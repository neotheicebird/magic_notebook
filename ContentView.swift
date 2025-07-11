import SwiftUI

struct ContentView: View {
    @StateObject private var noteStore = NoteStore()
    @State private var showingEntryView = false
    @State private var selectedNote: Note?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                if noteStore.notes.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(noteStore.notes.sorted(by: { $0.lastEditedAt > $1.lastEditedAt })) { note in
                            NoteRowView(note: note, noteStore: noteStore) {
                                selectedNote = note
                                showingEntryView = true
                            }
                        }
                        .onDelete(perform: noteStore.deleteNote)
                    }
                    .listStyle(PlainListStyle())
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            selectedNote = nil
                            showingEntryView = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Magic Notes")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingEntryView) {
            EntryView(note: selectedNote, noteStore: noteStore)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Notes Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Tap the pencil icon below to create your first note")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Note Row View
struct NoteRowView: View {
    let note: Note
    let noteStore: NoteStore
    let onTap: () -> Void
    
    @State private var showingMetadata = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main note content
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    if !note.content.isEmpty {
                        Text(note.content)
                            .font(.body)
                            .lineLimit(2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Tags preview
                    if !note.tags.isEmpty {
                        HStack {
                            ForEach(note.tags.prefix(3), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            if note.tags.count > 3 {
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
                MetadataView(note: note)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingMetadata)
    }
}

// MARK: - Metadata View
struct MetadataView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Created", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(note.formattedCreatedDate)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("Last Edited", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(note.formattedLastEditedDate)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Word Count", systemImage: "textformat.123")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(note.wordCount) words")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("Reading Time", systemImage: "book")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(note.estimatedReadingTime)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            
            // Tags
            if !note.tags.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Tags", systemImage: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 4) {
                        ForEach(note.tags, id: \.self) { tag in
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
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    ContentView()
} 