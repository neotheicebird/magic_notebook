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
            VStack(spacing: 0) {
                // Auto-save indicator
                if hasUnsavedChanges {
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)
                        Text("Auto-saving...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                
                // Document Editor Content
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(document.blocks.enumerated()), id: \.element.id) { index, block in
                            BlockEditorView(
                                block: block,
                                isFocused: focusedBlock == block.id,
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
                                    addNewBlockWithUndo(after: block.id)
                                },
                                onDeletePressed: {
                                    deleteBlockWithUndo(block.id)
                                },
                                onBlockTypeChanged: { newType in
                                    changeBlockTypeWithUndo(block.id, to: newType)
                                }
                            )
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("\(block.blockType.displayName) block \(index + 1) of \(document.blocks.count)")
                            .accessibilityHint(block.isEmpty ? "Empty block, double tap to edit" : "Contains: \(block.content)")
                        }
                        
                        // Add new block button
                        Button(action: {
                            addNewBlockWithUndo(after: document.blocks.last?.id ?? UUID())
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                                Text("Add Block")
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .accessibilityLabel("Add new block")
                        .accessibilityHint("Adds a new paragraph block at the end of the document")
                    }
                    .padding()
                }
                
                // Tag generation indicator
                if isGeneratingTags {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating smart tags...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("< Back") {
                        saveDocument()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    HStack {
                        Button(action: {
                            if undoManager.undo(on: &document) {
                                markAsChanged()
                            }
                        }) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.title3)
                        }
                        .disabled(!undoManager.canUndo)
                        .accessibilityLabel("Undo")
                        .accessibilityHint("Undo the last action")
                        .keyboardShortcut("z", modifiers: .command)
                        
                        Button(action: {
                            if undoManager.redo(on: &document) {
                                markAsChanged()
                            }
                        }) {
                            Image(systemName: "arrow.uturn.forward")
                                .font(.title3)
                        }
                        .disabled(!undoManager.canRedo)
                        .accessibilityLabel("Redo")
                        .accessibilityHint("Redo the last undone action")
                        .keyboardShortcut("z", modifiers: [.command, .shift])
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                        }
                        .disabled(document.isEmpty)
                        .accessibilityLabel("Share document")
                        .accessibilityHint("Share or export this document")
                        
                        Button("Done") {
                            saveDocument()
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .disabled(document.isEmpty)
                        .accessibilityLabel("Done editing")
                        .accessibilityHint("Save document and return to document list")
                        .keyboardShortcut("s", modifiers: .command)
                    }
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
                // Focus on first empty paragraph block (skip heading)
                if document.blocks.count > 1 {
                    focusedBlock = document.blocks[1].id
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
}

// MARK: - Block Editor View
struct BlockEditorView: View {
    let block: DocumentBlock
    let isFocused: Bool
    let onContentChanged: (String) -> Void
    let onFocusChanged: (Bool) -> Void
    let onReturnPressed: () -> Void
    let onDeletePressed: () -> Void
    let onBlockTypeChanged: (BlockType) -> Void
    
    @State private var content: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Block type indicator
            HStack {
                Button(action: {
                    let newType: BlockType = block.blockType == .heading ? .paragraph : .heading
                    onBlockTypeChanged(newType)
                }) {
                    Text(block.blockType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(isHovering ? 0.3 : 0.2))
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.2), value: isHovering)
                }
                .accessibilityLabel("Block type: \(block.blockType.displayName)")
                .accessibilityHint("Double tap to switch block type")
                .onHover { hovering in
                    isHovering = hovering
                }
                
                Spacer()
                
                // Delete button for non-heading blocks when there's content
                if block.blockType != .heading && !block.isEmpty {
                    Button(action: onDeletePressed) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .accessibilityLabel("Delete block")
                    .accessibilityHint("Delete this block")
                }
            }
            
            // Text editor based on block type
            Group {
                if block.blockType == .heading {
                    TextField("Enter heading...", text: $content, axis: .vertical)
                        .font(.title2)
                        .fontWeight(.bold)
                        .focused($isTextFieldFocused)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .accessibilityLabel("Heading block")
                        .accessibilityHint("Enter heading text")
                } else {
                    TextField("Enter paragraph...", text: $content, axis: .vertical)
                        .font(.body)
                        .focused($isTextFieldFocused)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .lineLimit(nil)
                        .accessibilityLabel("Paragraph block")
                        .accessibilityHint("Enter paragraph text")
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            )
        }
        .animation(.easeInOut(duration: 0.2), value: block.blockType)
        .onAppear {
            content = block.content
            if isFocused {
                isTextFieldFocused = true
            }
        }
        .onChange(of: content) { newContent in
            onContentChanged(newContent)
        }
        .onChange(of: isTextFieldFocused) { focused in
            onFocusChanged(focused)
        }
        .onChange(of: isFocused) { focused in
            isTextFieldFocused = focused
        }
        .onSubmit {
            onReturnPressed()
        }
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