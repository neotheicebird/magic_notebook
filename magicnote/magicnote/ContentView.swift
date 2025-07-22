import SwiftUI

struct ContentView: View {
    @StateObject private var documentStore = DocumentStore()
    @State private var showingDocumentEditor = false
    @State private var selectedDocument: Document?
    @State private var searchText = ""
    @State private var showingTemplateSelector = false
    @State private var showingStatistics = false
    @State private var isToolbarVisible = true
    @State private var lastScrollOffset: CGFloat = 0
    @State private var scrollTimer: Timer?
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Custom header with left-aligned icon and title
                    HStack {
                        Image("24-code-editor")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundColor(.primary)
                        
                        Text("Entries")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Search bar
                    if filteredDocuments.isEmpty {
                        if documentStore.documents.isEmpty {
                            EmptyStateView()
                        } else {
                            SearchEmptyStateView()
                        }
                    } else {
                        ScrollView {
                            LazyVStack {
                                ForEach(filteredDocuments) { document in
                                    DocumentRowView(document: document, documentStore: documentStore) {
                                        selectedDocument = document
                                        showingDocumentEditor = true
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            lastScrollOffset = geometry.frame(in: .global).minY
                                        }
                                        .onChange(of: geometry.frame(in: .global).minY) { oldValue, newValue in
                                            let currentOffset = newValue
                                            let threshold: CGFloat = 5
                                            
                                            // If scroll position changed significantly, hide toolbar
                                            if abs(currentOffset - lastScrollOffset) > threshold {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    isToolbarVisible = false
                                                }
                                                
                                                // Cancel existing timer
                                                scrollTimer?.invalidate()
                                                
                                                // Start new timer to show toolbar when scrolling stops
                                                scrollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        isToolbarVisible = true
                                                    }
                                                }
                                            }
                                            lastScrollOffset = currentOffset
                                        }
                                }
                            )
                        }
                    }
                    
                    // Add padding to prevent content from being hidden behind bottom toolbar
                    Spacer()
                        .frame(height: isToolbarVisible ? 70 : 20)
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search documents...")
                
                // Bottom Toolbar - animate in/out based on scroll
                VStack {
                    Spacer()
                    BottomToolbarView(
                        onFolderTapped: {
                            // Placeholder - do nothing for now
                        },
                        onStarTapped: {
                            showingStatistics = true
                        },
                        onSwapTapped: {
                            // Placeholder - do nothing for now
                        },
                        onPenTapped: {
                            showingTemplateSelector = true
                        }
                    )
                    .offset(y: isToolbarVisible ? 0 : 100)
                    .animation(.easeInOut(duration: 0.3), value: isToolbarVisible)
                }
            }
        }
        .fullScreenCover(isPresented: $showingDocumentEditor) {
            DocumentEditorView(document: selectedDocument, documentStore: documentStore)
        }
        .sheet(isPresented: $showingTemplateSelector) {
            TemplateSelectorView(documentStore: documentStore) { document in
                selectedDocument = document
                showingTemplateSelector = false
                showingDocumentEditor = true
            }
        }
        .sheet(isPresented: $showingStatistics) {
            DocumentStatisticsView(documentStore: documentStore)
        }
        .onAppear {
            setupKeyboardShortcuts()
        }
        .onDisappear {
            scrollTimer?.invalidate()
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredDocuments: [Document] {
        if searchText.isEmpty {
            return documentStore.documents.sorted(by: { $0.lastEditedAt > $1.lastEditedAt })
        } else {
            return documentStore.searchDocuments(query: searchText).sorted(by: { $0.lastEditedAt > $1.lastEditedAt })
        }
    }
    
    // MARK: - Helper Methods
    
    private func deleteDocuments(at indexSet: IndexSet) {
        for index in indexSet {
            let document = filteredDocuments[index]
            documentStore.deleteDocument(document)
        }
    }
    
    private func setupKeyboardShortcuts() {
        // Keyboard shortcuts will be handled by the system
        // This is a placeholder for future keyboard shortcut implementation
    }

}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Documents Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Tap the pen icon in the bottom toolbar to create your first document")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

// MARK: - Search Empty State View
struct SearchEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Results Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Try adjusting your search terms or create a new document")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

// MARK: - Document Row View
struct DocumentRowView: View {
    let document: Document
    let documentStore: DocumentStore
    let onTap: () -> Void
    
    @State private var showingMetadata = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main document content
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.generatedTitle)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    // Show preview from first non-empty paragraph block
                    if let previewText = getPreviewText() {
                        Text(previewText)
                            .font(.body)
                            .lineLimit(2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Tags preview
                    if !document.tags.isEmpty {
                        HStack {
                            ForEach(document.tags.prefix(3), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            if document.tags.count > 3 {
                                Text("...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Info button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingMetadata.toggle()
                    }
                }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            
            // Metadata section
            if showingMetadata {
                DocumentMetadataView(document: document)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingMetadata)
    }
    
    private func getPreviewText() -> String? {
        for block in document.blocks {
            if block.blockType == .paragraph && !block.isEmpty {
                return block.content
            }
        }
        return nil
    }
}

// MARK: - Document Metadata View
struct DocumentMetadataView: View {
    let document: Document
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Created", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedDate(document.createdAt))
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("Last Edited", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedDate(document.lastEditedAt))
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Word Count", systemImage: "textformat.123")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(document.totalWordCount) words")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("Reading Time", systemImage: "book")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(document.estimatedReadingTime)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Blocks", systemImage: "square.stack.3d.up")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(document.blocks.count) blocks")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("Version", systemImage: "doc.badge.gearshape")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(document.version.uuidString.prefix(8))
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            
            // Tags
            if !document.tags.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Tags", systemImage: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 4) {
                        ForEach(document.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Template Selector View
struct TemplateSelectorView: View {
    let documentStore: DocumentStore
    let onTemplateSelected: (Document) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Templates") {
                    TemplateButton(
                        title: "Blank Document",
                        subtitle: "Start with a heading and paragraph",
                        icon: "doc"
                    ) {
                        let document = Document()
                        onTemplateSelected(document)
                    }
                    
                    TemplateButton(
                        title: "Meeting Notes",
                        subtitle: "Template for meeting notes",
                        icon: "person.2"
                    ) {
                        let document = createMeetingNotesTemplate()
                        onTemplateSelected(document)
                    }
                    
                    TemplateButton(
                        title: "Daily Journal",
                        subtitle: "Template for daily journaling",
                        icon: "book"
                    ) {
                        let document = createDailyJournalTemplate()
                        onTemplateSelected(document)
                    }
                    
                    TemplateButton(
                        title: "Task List",
                        subtitle: "Template for task management",
                        icon: "checklist"
                    ) {
                        let document = createTaskListTemplate()
                        onTemplateSelected(document)
                    }
                }
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createMeetingNotesTemplate() -> Document {
        var document = Document()
        document.blocks = [
            DocumentBlock(blockType: .heading, content: "Meeting Notes"),
            DocumentBlock(blockType: .paragraph, content: "Date: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none))"),
            DocumentBlock(blockType: .paragraph, content: "Attendees: "),
            DocumentBlock(blockType: .heading, content: "Agenda"),
            DocumentBlock(blockType: .paragraph, content: "• "),
            DocumentBlock(blockType: .heading, content: "Action Items"),
            DocumentBlock(blockType: .paragraph, content: "• ")
        ]
        return document
    }
    
    private func createDailyJournalTemplate() -> Document {
        var document = Document()
        document.blocks = [
            DocumentBlock(blockType: .heading, content: "Daily Journal"),
            DocumentBlock(blockType: .paragraph, content: DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .none)),
            DocumentBlock(blockType: .heading, content: "Today's Highlights"),
            DocumentBlock(blockType: .paragraph, content: ""),
            DocumentBlock(blockType: .heading, content: "Reflections"),
            DocumentBlock(blockType: .paragraph, content: ""),
            DocumentBlock(blockType: .heading, content: "Tomorrow's Goals"),
            DocumentBlock(blockType: .paragraph, content: "")
        ]
        return document
    }
    
    private func createTaskListTemplate() -> Document {
        var document = Document()
        document.blocks = [
            DocumentBlock(blockType: .heading, content: "Task List"),
            DocumentBlock(blockType: .paragraph, content: "Priority: High"),
            DocumentBlock(blockType: .paragraph, content: "□ "),
            DocumentBlock(blockType: .paragraph, content: "Priority: Medium"),
            DocumentBlock(blockType: .paragraph, content: "□ "),
            DocumentBlock(blockType: .paragraph, content: "Priority: Low"),
            DocumentBlock(blockType: .paragraph, content: "□ ")
        ]
        return document
    }
}

// MARK: - Template Button
struct TemplateButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Bottom Toolbar View
struct BottomToolbarView: View {
    let onFolderTapped: () -> Void
    let onStarTapped: () -> Void
    let onSwapTapped: () -> Void
    let onPenTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Folder button
            ToolbarButton(iconName: "24-folder") {
                onFolderTapped()
            }
            .disabled(true) // Disabled for now as specified
            
            Spacer()
            
            // Star-sparkle button (Statistics)
            ToolbarButton(iconName: "24-star-sparkle") {
                onStarTapped()
            }
            
            Spacer()
            
            // Swap button
            ToolbarButton(iconName: "24-swap") {
                onSwapTapped()
            }
            .disabled(true) // Disabled for now as specified
            
            Spacer()
            
            // Pen button (Create document)
            ToolbarButton(iconName: "24-pen") {
                onPenTapped()
            }
        }
        .padding(.horizontal, 40) // Equal spacing from edges
        .padding(.vertical, 8)
        .frame(height: 49) // Standard iOS toolbar height
        .background(.ultraThinMaterial) // Liquid glass effect
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
    }
}

// MARK: - Toolbar Button
struct ToolbarButton: View {
    let iconName: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        Button(action: action) {
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(isEnabled ? .primary : .secondary.opacity(0.5))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
} 