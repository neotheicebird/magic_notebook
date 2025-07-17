import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Document
struct Document: FileDocument, Identifiable, Codable {
    // Document metadata
    var id: UUID
    var version: UUID
    var createdAt: Date
    var lastEditedAt: Date
    var author: String
    var active: Bool
    var title: String
    
    // Document content
    var blocks: [DocumentBlock]
    
    // Cursor tracking
    var cursorPosition: CursorPosition
    
    // Auto-generated tags
    var tags: [String]
    
    // FileDocument conformance
    static var readableContentTypes: [UTType] {
        [.json]
    }
    
    static var writableContentTypes: [UTType] {
        [.json]
    }
    
    // MARK: - Initialization
    
    init() {
        self.id = UUID()
        self.version = UUID()
        let now = Date()
        self.createdAt = now
        self.lastEditedAt = now
        self.author = "User" // Could be device name or user preference
        self.active = true
        self.title = ""
        self.cursorPosition = CursorPosition()
        self.tags = []
        
        // Initialize with default blocks: heading + paragraph
        self.blocks = [
            DocumentBlock(blockType: .heading, content: ""),
            DocumentBlock(blockType: .paragraph, content: "")
        ]
        
        // Set cursor to first block (heading)
        if let firstBlock = blocks.first {
            self.cursorPosition.blockId = firstBlock.id
            self.cursorPosition.position = 0
        }
    }
    
    // Initialize from existing document
    init(from document: Document) {
        self.id = document.id
        self.version = UUID() // Generate new version
        self.createdAt = document.createdAt
        self.lastEditedAt = Date()
        self.author = document.author
        self.active = document.active
        self.title = document.title
        self.blocks = document.blocks
        self.cursorPosition = document.cursorPosition
        self.tags = document.tags
    }
    
    // MARK: - FileDocument Implementation
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let documentData = try decoder.decode(DocumentData.self, from: data)
        
        self.id = documentData.id
        self.version = documentData.version
        self.createdAt = documentData.createdAt
        self.lastEditedAt = documentData.lastEditedAt
        self.author = documentData.author
        self.active = documentData.active
        self.title = documentData.title
        self.blocks = documentData.blocks
        self.cursorPosition = documentData.cursorPosition
        self.tags = documentData.tags
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let documentData = DocumentData(
            id: id,
            version: version,
            createdAt: createdAt,
            lastEditedAt: lastEditedAt,
            author: author,
            active: active,
            title: title,
            blocks: blocks,
            cursorPosition: cursorPosition,
            tags: tags
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(documentData)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Document Data (for JSON serialization)
private struct DocumentData: Codable {
    let id: UUID
    let version: UUID
    let createdAt: Date
    let lastEditedAt: Date
    let author: String
    let active: Bool
    let title: String
    let blocks: [DocumentBlock]
    let cursorPosition: CursorPosition
    let tags: [String]
}

// MARK: - Cursor Position
struct CursorPosition: Codable {
    var blockId: UUID
    var position: Int
    
    init() {
        self.blockId = UUID()
        self.position = 0
    }
    
    init(blockId: UUID, position: Int = 0) {
        self.blockId = blockId
        self.position = position
    }
}

// MARK: - Document Extensions
extension Document {
    // Generate title from first non-empty block
    var generatedTitle: String {
        for block in blocks {
            let trimmedContent = block.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedContent.isEmpty {
                // Take first 50 characters
                return String(trimmedContent.prefix(50))
            }
        }
        return "Untitled Document"
    }
    
    // Get total word count
    var totalWordCount: Int {
        return blocks.reduce(0) { $0 + $1.wordCount }
    }
    
    // Get estimated reading time
    var estimatedReadingTime: String {
        let wordsPerMinute = 200.0
        let minutes = Double(totalWordCount) / wordsPerMinute
        
        if minutes < 1 {
            return "< 1 min"
        } else if minutes < 60 {
            return "\(Int(minutes)) min"
        } else {
            let hours = Int(minutes / 60)
            let remainingMinutes = Int(minutes.truncatingRemainder(dividingBy: 60))
            return "\(hours)h \(remainingMinutes)m"
        }
    }
    
    // Update document timestamp
    mutating func updateLastEditedTime() {
        self.lastEditedAt = Date()
        self.version = UUID() // Generate new version on edit
    }
    
    // Add a new block after specified block
    mutating func addBlock(after blockId: UUID, blockType: BlockType = .paragraph) {
        guard let index = blocks.firstIndex(where: { $0.id == blockId }) else { return }
        let newBlock = DocumentBlock(blockType: blockType)
        blocks.insert(newBlock, at: index + 1)
        updateLastEditedTime()
    }
    
    // Remove a block
    mutating func removeBlock(with blockId: UUID) {
        blocks.removeAll { $0.id == blockId }
        updateLastEditedTime()
    }
    
    // Update block content
    mutating func updateBlock(with blockId: UUID, content: String) {
        guard let index = blocks.firstIndex(where: { $0.id == blockId }) else { return }
        blocks[index].updateContent(content)
        updateLastEditedTime()
    }
    
    // Update cursor position
    mutating func updateCursorPosition(blockId: UUID, position: Int) {
        self.cursorPosition = CursorPosition(blockId: blockId, position: position)
        updateLastEditedTime()
    }
    
    // Check if document is empty
    var isEmpty: Bool {
        return blocks.allSatisfy { $0.isEmpty }
    }
} 