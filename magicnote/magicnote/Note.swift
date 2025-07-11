import Foundation

// MARK: - Note Model
struct Note: Identifiable, Codable {
    let id = UUID()
    var title: String
    var content: String
    var tags: [String]
    var createdAt: Date
    var lastEditedAt: Date
    
    // Computed properties for metadata
    var wordCount: Int {
        content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
    
    var estimatedReadingTime: String {
        let wordsPerMinute = 200.0
        let minutes = Double(wordCount) / wordsPerMinute
        
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
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    var formattedLastEditedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastEditedAt)
    }
    
    // Initialize new note
    init(title: String = "", content: String = "") {
        self.title = title
        self.content = content
        self.tags = []
        self.createdAt = Date()
        self.lastEditedAt = Date()
    }
    
    // Update last edited time
    mutating func updateLastEditedTime() {
        self.lastEditedAt = Date()
    }
} 