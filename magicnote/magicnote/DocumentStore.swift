import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Document Store
class DocumentStore: ObservableObject {
    @Published var documents: [Document] = []
    
    private let documentsDirectory: URL
    private let fileManager = FileManager.default
    private let documentExtension = "json"
    
    // MARK: - Initialization
    
    init() {
        // Create documents directory in app's documents folder
        let appDocumentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.documentsDirectory = appDocumentsPath.appendingPathComponent("MagicNotes", isDirectory: true)
        
        // Create directory if it doesn't exist
        createDocumentsDirectoryIfNeeded()
        
        // Load existing documents
        loadDocuments()
    }
    
    // MARK: - Directory Management
    
    private func createDocumentsDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: documentsDirectory.path) {
            do {
                try fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
                print("Created documents directory: \(documentsDirectory.path)")
            } catch {
                print("Failed to create documents directory: \(error.localizedDescription)")
            }
        }
    }
    
    private func documentURL(for documentId: UUID) -> URL {
        return documentsDirectory.appendingPathComponent("\(documentId.uuidString).\(documentExtension)")
    }
    
    // MARK: - Document Operations
    
    func createDocument() -> Document {
        let document = Document()
        documents.append(document)
        saveDocument(document)
        return document
    }
    
    func saveDocument(_ document: Document) {
        // Validate document before saving
        guard validateDocument(document) else {
            print("Document validation failed, skipping save")
            return
        }
        
        let url = documentURL(for: document.id)
        
        do {
            // Create backup before saving
            createBackupIfNeeded(for: document.id)
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            let data = try encoder.encode(document)
            
            // Atomic write - write to temporary file first, then rename
            let tempURL = url.appendingPathExtension("tmp")
            try data.write(to: tempURL)
            
            // Verify the written data can be read back
            let _ = try Data(contentsOf: tempURL)
            
            // Replace original file with temporary file
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
            try fileManager.moveItem(at: tempURL, to: url)
            
            // Update in-memory array
            if let index = documents.firstIndex(where: { $0.id == document.id }) {
                documents[index] = document
            } else {
                documents.append(document)
            }
            
            print("Saved document: \(document.generatedTitle)")
        } catch {
            print("Failed to save document: \(error.localizedDescription)")
            // Attempt recovery
            recoverFromSaveError(for: document.id, error: error)
        }
    }
    
    private func validateDocument(_ document: Document) -> Bool {
        // Basic validation checks
        guard !document.id.uuidString.isEmpty else {
            print("Document validation failed: Invalid ID")
            return false
        }
        
        guard !document.blocks.isEmpty else {
            print("Document validation failed: No blocks")
            return false
        }
        
        // Check for duplicate block IDs
        let blockIds = document.blocks.map { $0.id }
        guard Set(blockIds).count == blockIds.count else {
            print("Document validation failed: Duplicate block IDs")
            return false
        }
        
        // Validate dates
        guard document.createdAt <= document.lastEditedAt else {
            print("Document validation failed: Invalid dates")
            return false
        }
        
        return true
    }
    
    private func createBackupIfNeeded(for documentId: UUID) {
        let originalURL = documentURL(for: documentId)
        guard fileManager.fileExists(atPath: originalURL.path) else { return }
        
        let backupURL = originalURL.appendingPathExtension("backup")
        
        do {
            if fileManager.fileExists(atPath: backupURL.path) {
                try fileManager.removeItem(at: backupURL)
            }
            try fileManager.copyItem(at: originalURL, to: backupURL)
        } catch {
            print("Failed to create backup: \(error.localizedDescription)")
        }
    }
    
    private func recoverFromSaveError(for documentId: UUID, error: Error) {
        let originalURL = documentURL(for: documentId)
        let backupURL = originalURL.appendingPathExtension("backup")
        
        // Try to restore from backup
        if fileManager.fileExists(atPath: backupURL.path) {
            do {
                if fileManager.fileExists(atPath: originalURL.path) {
                    try fileManager.removeItem(at: originalURL)
                }
                try fileManager.copyItem(at: backupURL, to: originalURL)
                print("Recovered document from backup")
            } catch {
                print("Failed to recover from backup: \(error.localizedDescription)")
            }
        }
    }
    
    func loadDocuments() {
        documents.removeAll()
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            let jsonFiles = fileURLs.filter { $0.pathExtension == documentExtension }
            
            for fileURL in jsonFiles {
                if let document = loadDocument(from: fileURL) {
                    // Only load active documents
                    if document.active {
                        documents.append(document)
                    }
                }
            }
            
            // Sort by last edited time (most recent first)
            documents.sort { $0.lastEditedAt > $1.lastEditedAt }
            
            print("Loaded \(documents.count) documents")
        } catch {
            print("Failed to load documents: \(error.localizedDescription)")
        }
    }
    
    private func loadDocument(from url: URL) -> Document? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let document = try decoder.decode(Document.self, from: data)
            return document
        } catch {
            print("Failed to load document from \(url.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }
    
    func updateDocument(_ document: Document) {
        var updatedDocument = document
        updatedDocument.updateLastEditedTime()
        saveDocument(updatedDocument)
    }
    
    func deleteDocument(_ document: Document) {
        // Mark as inactive instead of actually deleting
        var updatedDocument = document
        updatedDocument.active = false
        saveDocument(updatedDocument)
        
        // Remove from memory
        documents.removeAll { $0.id == document.id }
    }
    
    func deleteDocument(at indexSet: IndexSet) {
        for index in indexSet {
            let document = documents[index]
            deleteDocument(document)
        }
    }
    
    // MARK: - File Management
    
    func permanentlyDeleteDocument(_ document: Document) {
        let url = documentURL(for: document.id)
        
        do {
            try fileManager.removeItem(at: url)
            documents.removeAll { $0.id == document.id }
            print("Permanently deleted document: \(document.generatedTitle)")
        } catch {
            print("Failed to permanently delete document: \(error.localizedDescription)")
        }
    }
    
    func getDocumentFileSize(_ document: Document) -> String {
        let url = documentURL(for: document.id)
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            }
        } catch {
            print("Failed to get file size: \(error.localizedDescription)")
        }
        
        return "Unknown"
    }
    
    // MARK: - Search and Filtering
    
    func searchDocuments(query: String) -> [Document] {
        guard !query.isEmpty else { return documents }
        
        let lowercaseQuery = query.lowercased()
        return documents.filter { document in
            // Search in title
            if document.generatedTitle.lowercased().contains(lowercaseQuery) {
                return true
            }
            
            // Search in block content
            for block in document.blocks {
                if block.content.lowercased().contains(lowercaseQuery) {
                    return true
                }
            }
            
            // Search in tags
            for tag in document.tags {
                if tag.lowercased().contains(lowercaseQuery) {
                    return true
                }
            }
            
            return false
        }
    }
    
    func documentsWithTag(_ tag: String) -> [Document] {
        return documents.filter { $0.tags.contains(tag) }
    }
    
    // MARK: - Statistics
    
    var totalDocuments: Int {
        return documents.count
    }
    
    var totalWords: Int {
        return documents.reduce(0) { $0 + $1.totalWordCount }
    }
    
    var totalFileSize: String {
        var totalSize: Int64 = 0
        
        for document in documents {
            let url = documentURL(for: document.id)
            do {
                let attributes = try fileManager.attributesOfItem(atPath: url.path)
                if let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            } catch {
                continue
            }
        }
        
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    // MARK: - Auto-tagging Integration
    
    func generateTags(for document: Document, completion: @escaping ([String]) -> Void) {
        // Create a combined text from all blocks
        let combinedText = document.blocks.map { $0.content }.joined(separator: " ").lowercased()
        var tags: [String] = []
        
        // Simple keyword-based tagging (enhanced from original)
        let keywords = [
            "meeting": "meeting",
            "idea": "idea",
            "brainstorm": "idea",
            "thought": "idea",
            "todo": "todo",
            "task": "task",
            "action": "task",
            "reminder": "reminder",
            "remember": "reminder",
            "important": "important",
            "urgent": "urgent",
            "priority": "urgent",
            "project": "project",
            "work": "work",
            "business": "work",
            "personal": "personal",
            "travel": "travel",
            "trip": "travel",
            "shopping": "shopping",
            "buy": "shopping",
            "purchase": "shopping",
            "health": "health",
            "medical": "health",
            "fitness": "health",
            "finance": "finance",
            "money": "finance",
            "budget": "finance",
            "education": "education",
            "learn": "education",
            "study": "education",
            "research": "research",
            "note": "note",
            "draft": "draft",
            "recipe": "recipe",
            "food": "recipe"
        ]
        
        // Add block-type based tags
        let hasHeading = document.blocks.contains { $0.blockType == .heading && !$0.isEmpty }
        
        if hasHeading {
            tags.append("structured")
        }
        
        // Content-based keyword detection
        for (keyword, tag) in keywords {
            if combinedText.contains(keyword) {
                tags.append(tag)
            }
        }
        
        // Add length-based tags
        if document.totalWordCount > 500 {
            tags.append("long-form")
        } else if document.totalWordCount > 100 {
            tags.append("medium")
        } else {
            tags.append("short")
        }
        
        // Add general tag if no specific tags were found
        if tags.isEmpty {
            tags.append("general")
        }
        
        // Remove duplicates
        tags = Array(Set(tags))
        
        // Simulate async processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(tags)
        }
    }
    
    func addTags(to documentId: UUID, tags: [String]) {
        guard let index = documents.firstIndex(where: { $0.id == documentId }) else { return }
        
        var document = documents[index]
        document.tags = Array(Set(document.tags + tags)) // Remove duplicates
        saveDocument(document)
    }
} 