import Foundation
import SwiftUI

// MARK: - Note Store
class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    
    private let userDefaults = UserDefaults.standard
    private let notesKey = "SavedNotes"
    
    init() {
        loadNotes()
    }
    
    // MARK: - Core Operations
    
    func addNote(_ note: Note) {
        notes.append(note)
        saveNotes()
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.updateLastEditedTime()
            notes[index] = updatedNote
            saveNotes()
        }
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
    
    func deleteNote(at indexSet: IndexSet) {
        notes.remove(atOffsets: indexSet)
        saveNotes()
    }
    
    // MARK: - Persistence
    
    private func saveNotes() {
        do {
            let data = try JSONEncoder().encode(notes)
            userDefaults.set(data, forKey: notesKey)
        } catch {
            print("Failed to save notes: \(error.localizedDescription)")
        }
    }
    
    private func loadNotes() {
        guard let data = userDefaults.data(forKey: notesKey) else {
            // No saved notes, start with empty array
            return
        }
        
        do {
            notes = try JSONDecoder().decode([Note].self, from: data)
        } catch {
            print("Failed to load notes: \(error.localizedDescription)")
            notes = []
        }
    }
    
    // MARK: - Smart Actions
    
    func generateTags(for note: Note, completion: @escaping ([String]) -> Void) {
        // For now, we'll implement a simple tag generation system
        // In a real app, this would use Apple's Natural Language framework
        // or integrate with Apple Intelligence APIs
        
        let text = "\(note.title) \(note.content)".lowercased()
        var tags: [String] = []
        
        // Simple keyword-based tagging
        let keywords = [
            "meeting": "meeting",
            "idea": "idea",
            "todo": "todo",
            "task": "task",
            "reminder": "reminder",
            "important": "important",
            "urgent": "urgent",
            "project": "project",
            "work": "work",
            "personal": "personal",
            "travel": "travel",
            "shopping": "shopping",
            "health": "health",
            "finance": "finance",
            "education": "education",
            "research": "research"
        ]
        
        for (keyword, tag) in keywords {
            if text.contains(keyword) {
                tags.append(tag)
            }
        }
        
        // Add a general tag if no specific tags were found
        if tags.isEmpty {
            tags.append("general")
        }
        
        // Simulate async processing (replace with actual AI processing)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(tags)
        }
    }
    
    func addTags(to noteId: UUID, tags: [String]) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].tags = Array(Set(notes[index].tags + tags)) // Remove duplicates
            saveNotes()
        }
    }
} 