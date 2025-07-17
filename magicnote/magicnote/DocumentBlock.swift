import Foundation

// MARK: - Block Types
enum BlockType: String, Codable, CaseIterable {
    case heading = "heading"
    case paragraph = "paragraph"
    
    var displayName: String {
        switch self {
        case .heading:
            return "Heading"
        case .paragraph:
            return "Paragraph"
        }
    }
}

// MARK: - Document Block
struct DocumentBlock: Identifiable, Codable {
    let id: UUID
    var blockType: BlockType
    var content: String
    var metadata: BlockMetadata
    
    init(blockType: BlockType, content: String = "") {
        self.id = UUID()
        self.blockType = blockType
        self.content = content
        self.metadata = BlockMetadata()
    }
    
    // Update content and metadata timestamp
    mutating func updateContent(_ newContent: String) {
        self.content = newContent
        self.metadata.lastEditedAt = Date()
    }
}

// MARK: - Block Metadata
struct BlockMetadata: Codable {
    var createdAt: Date
    var lastEditedAt: Date
    
    init() {
        let now = Date()
        self.createdAt = now
        self.lastEditedAt = now
    }
}

// MARK: - Block Extensions
extension DocumentBlock {
    // Check if block is empty
    var isEmpty: Bool {
        return content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Get word count for this block
    var wordCount: Int {
        return content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
} 