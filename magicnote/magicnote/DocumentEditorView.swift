import SwiftUI

// MARK: - Document Command Protocol
protocol DocumentCommand {
    func execute(on document: inout Document)
    func undo(on document: inout Document)
}

// MARK: - Content Change Command
struct ContentChangeCommand: DocumentCommand {
    let blockId: UUID
    let oldContent: String
    let newContent: String
    
    func execute(on document: inout Document) {
        document.updateBlock(with: blockId, content: newContent)
    }
    
    func undo(on document: inout Document) {
        document.updateBlock(with: blockId, content: oldContent)
    }
}

// MARK: - Block Type Change Command
struct BlockTypeChangeCommand: DocumentCommand {
    let blockId: UUID
    let oldType: BlockType
    let newType: BlockType
    
    func execute(on document: inout Document) {
        guard let index = document.blocks.firstIndex(where: { $0.id == blockId }) else { return }
        document.blocks[index].blockType = newType
        document.updateLastEditedTime()
    }
    
    func undo(on document: inout Document) {
        guard let index = document.blocks.firstIndex(where: { $0.id == blockId }) else { return }
        document.blocks[index].blockType = oldType
        document.updateLastEditedTime()
    }
}

// MARK: - Add Block Command
struct AddBlockCommand: DocumentCommand {
    let blockId: UUID
    let newBlock: DocumentBlock
    let insertIndex: Int
    
    func execute(on document: inout Document) {
        document.blocks.insert(newBlock, at: insertIndex)
        document.updateLastEditedTime()
    }
    
    func undo(on document: inout Document) {
        document.blocks.removeAll { $0.id == newBlock.id }
        document.updateLastEditedTime()
    }
}

// MARK: - Delete Block Command
struct DeleteBlockCommand: DocumentCommand {
    let deletedBlock: DocumentBlock
    let originalIndex: Int
    
    func execute(on document: inout Document) {
        document.blocks.removeAll { $0.id == deletedBlock.id }
        document.updateLastEditedTime()
    }
    
    func undo(on document: inout Document) {
        document.blocks.insert(deletedBlock, at: originalIndex)
        document.updateLastEditedTime()
    }
}

// MARK: - Undo Manager
class DocumentUndoManager: ObservableObject {
    private var undoStack: [DocumentCommand] = []
    private var redoStack: [DocumentCommand] = []
    private let maxUndoCount = 50
    
    @Published var canUndo = false
    @Published var canRedo = false
    
    func executeCommand(_ command: DocumentCommand, on document: inout Document) {
        command.execute(on: &document)
        
        // Add to undo stack
        undoStack.append(command)
        
        // Clear redo stack when new command is executed
        redoStack.removeAll()
        
        // Limit undo stack size
        if undoStack.count > maxUndoCount {
            undoStack.removeFirst()
        }
        
        updateStates()
    }
    
    func undo(on document: inout Document) -> Bool {
        guard let command = undoStack.popLast() else { return false }
        
        command.undo(on: &document)
        redoStack.append(command)
        
        updateStates()
        return true
    }
    
    func redo(on document: inout Document) -> Bool {
        guard let command = redoStack.popLast() else { return false }
        
        command.execute(on: &document)
        undoStack.append(command)
        
        updateStates()
        return true
    }
    
    private func updateStates() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
    
    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
        updateStates()
    }
}

// MARK: - Document Editor View
struct DocumentEditorView: View {
    @ObservedObject var documentStore: DocumentStore
    @State private var document: Document
    @State private var isGeneratingTags = false
    @State private var showingShareSheet = false
    @State private var lastSaveTime = Date()
    @State private var autoSaveTimer: Timer?
    @State private var hasUnsavedChanges = false
    @State private var blockContentCache: [UUID: String] = [:]
    @StateObject private var undoManager = DocumentUndoManager()
    @Environment(\.dismiss) private var dismiss
    
    // Focus management
    @FocusState private var focusedBlock: UUID?
    
    // Track if this is a new document
    private let isNewDocument: Bool
    
    // Performance optimization - debounced auto-save
    private let autoSaveInterval: TimeInterval = 2.0
    
    // UI state for floating toolbar
    @State private var showingFloatingToolbar = false
    
    init(document: Document? = nil, documentStore: DocumentStore) {
        self.documentStore = documentStore
        if let existingDoc = document {
            self._document = State(initialValue: existingDoc)
            self.isNewDocument = false
        } else {
            self._document = State(initialValue: Document())
            self.isNewDocument = true
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Seamless Document Editor Content
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(document.blocks.enumerated()), id: \.element.id) { index, block in
                                SeamlessBlockEditorView(
                                    block: block,
                                    isFocused: focusedBlock == block.id,
                                    isFirstBlock: index == 0,
                                    onContentChanged: { newContent in
                                        updateBlockContentWithUndo(block.id, content: newContent)
                                    },
                                    onFocusChanged: { isFocused in
                                        if isFocused {
                                            focusedBlock = block.id
                                            document.updateCursorPosition(blockId: block.id, position: 0)
                                        }
                                    },
                                    onReturnPressed: {
                                        handleReturnFromBlock(block.id)
                                    },
                                    onDeletePressed: {
                                        handleDeleteFromBlock(block.id)
                                    },
                                    onDoubleNewline: {
                                        addNewBlockWithUndo(after: block.id)
                                    },
                                    onBackspaceAtStart: {
                                        mergeWithPreviousBlock(block.id)
                                    }
                                )
                                .accessibilityElement(children: .contain)
                                .accessibilityLabel("\(block.blockType.displayName) \(index + 1) of \(document.blocks.count)")
                                .accessibilityHint(block.isEmpty ? "Empty, tap to edit" : "Contains: \(block.content)")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100) // Space for floating toolbar
                    }
                }
                
                // Floating + Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                showingFloatingToolbar.toggle()
                            }
                        }) {
                            Image(systemName: showingFloatingToolbar ? "xmark" : "plus")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                        }
                        .rotationEffect(.degrees(showingFloatingToolbar ? 45 : 0))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showingFloatingToolbar)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, showingFloatingToolbar ? 80 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showingFloatingToolbar)
                }
                
                // Floating Toolbar
                if showingFloatingToolbar {
                    VStack {
                        Spacer()
                        HStack(spacing: 20) {
                            Button(action: {
                                _ = undoManager.undo(on: &document)
                                markAsChanged()
                            }) {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.purple)
                                    .clipShape(Circle())
                            }
                            .disabled(!undoManager.canUndo)
                            .accessibilityLabel("Undo")
                            
                            Button(action: {
                                _ = undoManager.redo(on: &document)
                                markAsChanged()
                            }) {
                                Image(systemName: "arrow.uturn.forward")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.purple)
                                    .clipShape(Circle())
                            }
                            .disabled(!undoManager.canRedo)
                            .accessibilityLabel("Redo")
                            
                            Button(action: {
                                showingShareSheet = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.purple)
                                    .clipShape(Circle())
                            }
                            .disabled(document.isEmpty)
                            .accessibilityLabel("Share document")
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        saveDocument()
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.purple)
                    }
                    .accessibilityLabel("Back to documents")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveDocument()
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.purple)
                    }
                    .disabled(document.isEmpty)
                    .accessibilityLabel("Done editing")
                    .keyboardShortcut("s", modifiers: .command)
                }
            }
        }
        .onAppear {
            setupInitialFocus()
            setupAutoSave()
            setupBlockContentCache()
        }
        .onDisappear {
            autoSaveTimer?.invalidate()
            if hasUnsavedChanges {
                saveDocument()
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(document: document)
        }
    }
    
    // MARK: - Auto-Save Management
    
    private func setupAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { _ in
            if hasUnsavedChanges && !document.isEmpty {
                saveDocumentSilently()
            }
        }
    }
    
    private func setupBlockContentCache() {
        blockContentCache = Dictionary(uniqueKeysWithValues: document.blocks.map { ($0.id, $0.content) })
    }
    
    private func markAsChanged() {
        hasUnsavedChanges = true
    }
    
    private func saveDocumentSilently() {
        guard !document.isEmpty else { return }
        
        // Update document title from first non-empty block
        document.title = document.generatedTitle
        
        // Save document
        documentStore.saveDocument(document)
        
        hasUnsavedChanges = false
        lastSaveTime = Date()
    }
    
    // MARK: - Block Management with Undo Support
    
    private func updateBlockContentWithUndo(_ blockId: UUID, content: String) {
        let oldContent = blockContentCache[blockId] ?? ""
        
        // Only create undo command if content actually changed
        if oldContent != content {
            let command = ContentChangeCommand(
                blockId: blockId,
                oldContent: oldContent,
                newContent: content
            )
            
            undoManager.executeCommand(command, on: &document)
            blockContentCache[blockId] = content
            markAsChanged()
        }
    }
    
    private func addNewBlockWithUndo(after blockId: UUID) {
        // Find the index of the block to add after
        guard let index = document.blocks.firstIndex(where: { $0.id == blockId }) else { return }
        
        // Create the new block
        let newBlock = DocumentBlock(blockType: .paragraph)
        let insertIndex = index + 1
        
        let command = AddBlockCommand(
            blockId: blockId,
            newBlock: newBlock,
            insertIndex: insertIndex
        )
        
        undoManager.executeCommand(command, on: &document)
        blockContentCache[newBlock.id] = newBlock.content
        markAsChanged()
        
        // Focus on the new block
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedBlock = newBlock.id
        }
    }
    
    private func deleteBlockWithUndo(_ blockId: UUID) {
        // Don't delete if it's the only block
        guard document.blocks.count > 1 else { return }
        
        // Find the block to delete
        guard let index = document.blocks.firstIndex(where: { $0.id == blockId }) else { return }
        let blockToDelete = document.blocks[index]
        
        let command = DeleteBlockCommand(
            deletedBlock: blockToDelete,
            originalIndex: index
        )
        
        undoManager.executeCommand(command, on: &document)
        blockContentCache.removeValue(forKey: blockId)
        markAsChanged()
        
        // Focus on previous block
        let previousIndex = max(0, index - 1)
        if previousIndex < document.blocks.count {
            let previousBlockId = document.blocks[previousIndex].id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedBlock = previousBlockId
            }
        }
    }
    
    private func changeBlockTypeWithUndo(_ blockId: UUID, to newType: BlockType) {
        guard let index = document.blocks.firstIndex(where: { $0.id == blockId }) else { return }
        let oldType = document.blocks[index].blockType
        
        // Only create undo command if type actually changed
        if oldType != newType {
            let command = BlockTypeChangeCommand(
                blockId: blockId,
                oldType: oldType,
                newType: newType
            )
            
            undoManager.executeCommand(command, on: &document)
            markAsChanged()
        }
    }
    
    // MARK: - Legacy methods for compatibility
    
    private func updateBlockContent(_ blockId: UUID, content: String) {
        document.updateBlock(with: blockId, content: content)
        markAsChanged()
    }
    
    private func addNewBlock(after blockId: UUID) {
        // Find the index of the block to add after
        guard let index = document.blocks.firstIndex(where: { $0.id == blockId }) else { return }
        
        // Create and insert the new block
        let newBlock = DocumentBlock(blockType: .paragraph)
        document.blocks.insert(newBlock, at: index + 1)
        document.updateLastEditedTime()
        markAsChanged()
        
        // Focus on the new block
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedBlock = newBlock.id
        }
    }
    
    private func deleteBlock(_ blockId: UUID) {
        // Don't delete if it's the only block
        guard document.blocks.count > 1 else { return }
        
        // Find the block to delete and focus on previous one
        if let index = document.blocks.firstIndex(where: { $0.id == blockId }) {
            let previousIndex = max(0, index - 1)
            let previousBlockId = document.blocks[previousIndex].id
            
            document.removeBlock(with: blockId)
            markAsChanged()
            
            // Focus on previous block
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedBlock = previousBlockId
            }
        }
    }
    
    private func changeBlockType(_ blockId: UUID, to newType: BlockType) {
        guard let index = document.blocks.firstIndex(where: { $0.id == blockId }) else { return }
        document.blocks[index].blockType = newType
        document.updateLastEditedTime()
        markAsChanged()
    }
    
    // MARK: - Focus Management
    
    private func setupInitialFocus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if isNewDocument {
                // Focus on first block (heading) for new documents
                if let firstBlock = document.blocks.first {
                    focusedBlock = firstBlock.id
                    document.updateCursorPosition(blockId: firstBlock.id, position: 0)
                }
            } else {
                // Focus on last block for existing documents
                if let lastBlock = document.blocks.last {
                    focusedBlock = lastBlock.id
                    document.updateCursorPosition(blockId: lastBlock.id, position: lastBlock.content.count)
                }
            }
        }
    }
    
    // MARK: - Document Management
    
    private func saveDocument() {
        // Don't save empty documents
        guard !document.isEmpty else { return }
        
        // Update document title from first non-empty block
        document.title = document.generatedTitle
        
        // Save document
        documentStore.saveDocument(document)
        
        hasUnsavedChanges = false
        lastSaveTime = Date()
        
        // Generate tags
        generateTagsForDocument()
    }
    
    private func generateTagsForDocument() {
        isGeneratingTags = true
        
        documentStore.generateTags(for: document) { tags in
            DispatchQueue.main.async {
                self.isGeneratingTags = false
                self.documentStore.addTags(to: self.document.id, tags: tags)
            }
        }
    }
    
    // MARK: - Block Management
    
    private func mergeWithPreviousBlock(_ blockId: UUID) {
        guard let index = document.blocks.firstIndex(where: { $0.id == blockId }) else { return }
        guard index > 0 else { return }
        
        let currentBlock = document.blocks[index]
        let previousBlock = document.blocks[index - 1]
        let mergedContent = previousBlock.content + currentBlock.content
        
        // Update the previous block with merged content
        let updateCommand = ContentChangeCommand(
            blockId: previousBlock.id,
            oldContent: previousBlock.content,
            newContent: mergedContent
        )
        
        // Delete the current block
        let deleteCommand = DeleteBlockCommand(
            deletedBlock: currentBlock,
            originalIndex: index
        )
        
        undoManager.executeCommand(updateCommand, on: &document)
        undoManager.executeCommand(deleteCommand, on: &document)
        
        blockContentCache.removeValue(forKey: currentBlock.id)
        blockContentCache[previousBlock.id] = mergedContent
        markAsChanged()
        
        // Focus on the merged block
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedBlock = previousBlock.id
        }
    }
    
    // MARK: - Block Management
    
    private func handleReturnFromBlock(_ blockId: UUID) {
        guard let index = document.blocks.firstIndex(where: { $0.id == blockId }) else { return }
        let currentBlock = document.blocks[index]
        
        if currentBlock.blockType == .heading {
            // If this is the first block (heading) and there's a second block, focus on it
            if index == 0 && document.blocks.count > 1 {
                focusedBlock = document.blocks[1].id
            } else {
                // Create a new paragraph block after the heading
                addNewBlockWithUndo(after: blockId)
            }
        } else {
            // For paragraph blocks, create a new block after
            addNewBlockWithUndo(after: blockId)
        }
    }
    
    private func handleDeleteFromBlock(_ blockId: UUID) {
        guard let index = document.blocks.firstIndex(where: { $0.id == blockId }) else { return }
        let currentBlock = document.blocks[index]
        
        // Only handle delete for empty paragraph blocks
        if currentBlock.blockType == .paragraph && currentBlock.isEmpty && index > 0 {
            let previousBlock = document.blocks[index - 1]
            
            // Delete the current empty block
            let deleteCommand = DeleteBlockCommand(
                deletedBlock: currentBlock,
                originalIndex: index
            )
            
            undoManager.executeCommand(deleteCommand, on: &document)
            blockContentCache.removeValue(forKey: currentBlock.id)
            markAsChanged()
            
            // Focus on the previous block at the end
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedBlock = previousBlock.id
                document.updateCursorPosition(blockId: previousBlock.id, position: previousBlock.content.count)
            }
        }
    }
}

// MARK: - Seamless Block Editor View
struct SeamlessBlockEditorView: View {
    let block: DocumentBlock
    let isFocused: Bool
    let isFirstBlock: Bool
    let onContentChanged: (String) -> Void
    let onFocusChanged: (Bool) -> Void
    let onReturnPressed: () -> Void
    let onDeletePressed: () -> Void
    let onDoubleNewline: () -> Void
    let onBackspaceAtStart: () -> Void
    
    @State private var content: String = ""
    @State private var lastContent: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        Group {
            if block.blockType == .heading {
                TextField("", text: $content, axis: .vertical)
                    .font(.title2)
                    .fontWeight(.bold)
                    .focused($isTextFieldFocused)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical, 8)
                    .accessibilityLabel("Heading")
                    .accessibilityHint("Enter heading text")
                    .onSubmit {
                        onReturnPressed()
                    }
            } else {
                TextField("", text: $content, axis: .vertical)
                    .font(.body)
                    .focused($isTextFieldFocused)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical, 4)
                    .lineLimit(nil)
                    .accessibilityLabel("Paragraph")
                    .accessibilityHint("Enter paragraph text")
                    .onSubmit {
                        onReturnPressed()
                    }
            }
        }
        .onAppear {
            content = block.content
            lastContent = block.content
            if isFocused {
                isTextFieldFocused = true
            }
        }
        .onChange(of: content) { _, newContent in
            handleContentChange(newContent)
        }
        .onChange(of: isTextFieldFocused) { _, focused in
            onFocusChanged(focused)
        }
        .onChange(of: isFocused) { _, focused in
            isTextFieldFocused = focused
        }
    }
    
    private func handleContentChange(_ newContent: String) {
        // Handle delete key for empty paragraph blocks
        if newContent.isEmpty && !lastContent.isEmpty && lastContent.count == 1 && block.blockType == .paragraph && !isFirstBlock {
            onDeletePressed()
            return
        }
        
        // Check for double newline to create new block
        if newContent.hasSuffix("\n\n") && !lastContent.hasSuffix("\n\n") {
            let trimmedContent = String(newContent.dropLast(2))
            onContentChanged(trimmedContent)
            onDoubleNewline()
            return
        }
        
        // Check for backspace at start to merge blocks
        if newContent.isEmpty && !lastContent.isEmpty && lastContent.count == 1 {
            onBackspaceAtStart()
            return
        }
        
        lastContent = newContent
        onContentChanged(newContent)
    }
}

// MARK: - Share Sheet
struct ShareSheet: View {
    let document: Document
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Export Options") {
                    Button(action: {
                        shareAsText()
                    }) {
                        HStack {
                            Image(systemName: "doc.plaintext")
                                .foregroundColor(.blue)
                            Text("Export as Plain Text")
                        }
                    }
                    
                    Button(action: {
                        shareAsMarkdown()
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text("Export as Markdown")
                        }
                    }
                }
                
                Section("Document Info") {
                    HStack {
                        Text("Title")
                        Spacer()
                        Text(document.generatedTitle)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Words")
                        Spacer()
                        Text("\(document.totalWordCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Blocks")
                        Spacer()
                        Text("\(document.blocks.count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Share Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func shareAsText() {
        let content = document.blocks.map { block in
            block.content
        }.joined(separator: "\n\n")
        
        let activityVC = UIActivityViewController(activityItems: [content], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func shareAsMarkdown() {
        let content = document.blocks.map { block in
            switch block.blockType {
            case .heading:
                return "# \(block.content)"
            case .paragraph:
                return block.content
            }
        }.joined(separator: "\n\n")
        
        let activityVC = UIActivityViewController(activityItems: [content], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Preview
#Preview {
    DocumentEditorView(documentStore: DocumentStore())
} 