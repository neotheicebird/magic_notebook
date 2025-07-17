import SwiftUI

struct ContentView: View {
    @StateObject private var documentStore = DocumentStore()
    @State private var showingDocumentEditor = false
    @State private var selectedDocument: Document?
    @State private var searchText = ""
    @State private var showingTemplateSelector = false
    @State private var showingStatistics = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Main content
                if filteredDocuments.isEmpty {
                    if documentStore.documents.isEmpty {
                        EmptyStateView()
                    } else {
                        SearchEmptyStateView()
                    }
                } else {
                    List {
                        ForEach(filteredDocuments) { document in
                            DocumentRowView(document: document, documentStore: documentStore) {
                                selectedDocument = document
                                showingDocumentEditor = true
                            }
                        }
                        .onDelete(perform: deleteDocuments)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search documents...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingStatistics = true
                    }) {
                        Image(systemName: "chart.bar")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("View statistics")
                    .accessibilityHint("View document statistics and analytics")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingTemplateSelector = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.8, green: 1.0, blue: 0.2)) // Lemon green
                    }
                    .accessibilityLabel("Create new document")
                    .accessibilityHint("Choose a template for a new document")
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
            
            Text("Tap the + icon above to create your first document")
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

#Preview {
    ContentView()
} 