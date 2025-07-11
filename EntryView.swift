import SwiftUI

struct EntryView: View {
    let note: Note?
    let noteStore: NoteStore
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var isGeneratingTags = false
    @Environment(\.dismiss) private var dismiss
    
    // Track if this is a new note or editing existing
    private var isNewNote: Bool {
        note == nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Title Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter title (optional)", text: $title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Content Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $content)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                .padding(.top)
                
                Spacer()
                
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveNote()
                    }
                    .fontWeight(.semibold)
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            if let note = note {
                // Editing existing note
                title = note.title
                content = note.content
            } else {
                // New note - focus on content
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Note: In a real app, you'd use FocusState to control focus
                    // For now, we'll just ensure the content field is ready
                }
            }
        }
    }
    
    private func saveNote() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Don't save empty notes
        guard !trimmedContent.isEmpty else {
            dismiss()
            return
        }
        
        if let existingNote = note {
            // Update existing note
            var updatedNote = existingNote
            updatedNote.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedNote.content = trimmedContent
            
            noteStore.updateNote(updatedNote)
            
            // Generate tags for updated note
            generateTagsForNote(updatedNote)
            
        } else {
            // Create new note
            let newNote = Note(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: trimmedContent
            )
            
            noteStore.addNote(newNote)
            
            // Generate tags for new note
            generateTagsForNote(newNote)
        }
        
        dismiss()
    }
    
    private func generateTagsForNote(_ note: Note) {
        isGeneratingTags = true
        
        noteStore.generateTags(for: note) { tags in
            DispatchQueue.main.async {
                self.isGeneratingTags = false
                self.noteStore.addTags(to: note.id, tags: tags)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    EntryView(note: nil, noteStore: NoteStore())
} 