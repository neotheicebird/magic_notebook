# Data Models

## Note Model

**File**: `Note.swift`

The `Note` struct is the core data model representing a single note in the application.

### Structure

```swift
struct Note: Identifiable, Codable {
    let id = UUID()
    var title: String
    var content: String
    var tags: [String]
    var createdAt: Date
    var lastEditedAt: Date
}
```

### Protocols Implemented

#### 1. Identifiable
- **Purpose**: Enables use in SwiftUI ForEach loops
- **Implementation**: Uses `UUID()` for unique identification
- **Benefit**: Automatic list item tracking and animations

#### 2. Codable
- **Purpose**: Enables JSON serialization/deserialization
- **Implementation**: Automatic synthesis by Swift compiler
- **Benefit**: Easy persistence to UserDefaults

### Core Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `UUID` | Unique identifier (auto-generated) |
| `title` | `String` | Note title (optional) |
| `content` | `String` | Main note content |
| `tags` | `[String]` | Auto-generated tags array |
| `createdAt` | `Date` | Creation timestamp |
| `lastEditedAt` | `Date` | Last modification timestamp |

### Computed Properties

The Note model includes several computed properties for enhanced functionality:

#### Word Count
```swift
var wordCount: Int {
    content.components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }
        .count
}
```
- Splits content by whitespace and newlines
- Filters out empty strings
- Returns accurate word count

#### Estimated Reading Time
```swift
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
```
- Based on 200 words per minute reading speed
- Handles edge cases (< 1 minute, > 1 hour)
- Returns human-readable format

#### Formatted Dates
```swift
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
```
- Consistent date formatting across the app
- Medium date style (e.g., "Jan 15, 2024")
- Short time style (e.g., "3:30 PM")

### Methods

#### Initialization
```swift
init(title: String = "", content: String = "") {
    self.title = title
    self.content = content
    self.tags = []
    self.createdAt = Date()
    self.lastEditedAt = Date()
}
```
- Default parameters for convenience
- Automatic timestamp generation
- Empty tags array initialization

#### Update Last Edited Time
```swift
mutating func updateLastEditedTime() {
    self.lastEditedAt = Date()
}
```
- Marks the note as recently modified
- Called automatically by NoteStore when updating

### Data Validation

The model includes implicit validation:
- **UUID uniqueness**: Guaranteed by UUID generation
- **Date consistency**: Automatic timestamp management
- **String safety**: Empty strings handled gracefully

### Usage Examples

#### Creating a New Note
```swift
let note = Note(title: "Meeting Notes", content: "Discuss project timeline")
```

#### Accessing Metadata
```swift
let wordCount = note.wordCount
let readingTime = note.estimatedReadingTime
let createdDate = note.formattedCreatedDate
```

## Data Relationships

### Note → Tags (One-to-Many)
- Each note can have multiple tags
- Tags are stored as a simple string array
- Duplicates are prevented in NoteStore

### Future Extensibility

The model is designed for easy extension:
- **Categories**: Could add `category: String` property
- **Priority**: Could add `priority: Priority` enum
- **Attachments**: Could add `attachments: [Attachment]` array
- **Sharing**: Could add `sharedWith: [User]` array

## Memory Footprint

The Note model is lightweight:
- **Struct**: Value type, efficient memory usage
- **Codable**: Minimal serialization overhead
- **Computed Properties**: No stored data overhead
- **UUID**: 16 bytes
- **Dates**: 8 bytes each
- **Strings**: Variable, but typically small for notes

## Best Practices

1. **Immutability**: Use `let` for properties that shouldn't change
2. **Default Values**: Provide sensible defaults in initializers
3. **Computed Properties**: Use for derived data to avoid inconsistency
4. **Validation**: Handle edge cases in computed properties
5. **Documentation**: Clear property names and computed property logic 