# Development Guide

## Quick Start

### Prerequisites
- Xcode 14.0 or later
- iOS 14.0+ deployment target
- Swift 5.5+

### Setup
1. Clone the repository
2. Open `magicnote/magicnote.xcodeproj`
3. Select iOS Simulator or device
4. Build and run (⌘+R)

## Code Structure Overview

### File Hierarchy
```
magicnote/magicnote/
├── magicnoteApp.swift          # App entry point
├── Document.swift              # Core document model + FileDocument
├── DocumentBlock.swift         # Block-based content model
├── DocumentStore.swift         # File-based document management
├── ContentView.swift           # Main document list interface
├── DocumentEditorView.swift    # Block-based document editing
└── Assets.xcassets/           # App icons and colors
```

### Key Responsibilities
- **Document.swift**: FileDocument protocol, JSON serialization, document metadata
- **DocumentBlock.swift**: Block types, content structure, block metadata
- **DocumentStore.swift**: File I/O, CRUD operations, auto-tagging, search
- **ContentView.swift**: Document list UI, navigation, metadata display
- **DocumentEditorView.swift**: Block-based editing, cursor management, focus handling

## Common Development Tasks

### Adding New Block Types

1. **Update the BlockType enum**:
```swift
// In DocumentBlock.swift
enum BlockType: String, Codable, CaseIterable {
    case heading = "heading"
    case paragraph = "paragraph"
    case newBlockType = "new_block_type"  // Add new type
}
```

2. **Update the UI**:
```swift
// In DocumentEditorView.swift - add handling for new block type
// In BlockEditorView.swift - add specific UI for new block type
```

### Adding New Document Properties

1. **Update the Document model**:
```swift
// In Document.swift
struct Document: FileDocument {
    // ... existing properties ...
    var newProperty: String = ""
}
```

2. **Update JSON serialization**:
```swift
// In Document.swift - DocumentData struct
private struct DocumentData: Codable {
    // ... existing properties ...
    let newProperty: String
}
```

3. **Handle migration** (if needed):
```swift
// In NoteStore.swift
private func migrateDataIfNeeded() {
    // Handle old data format
}
```

### Modifying the UI

#### Adding New Views
1. Create SwiftUI view file
2. Follow naming convention: `[Purpose]View.swift`
3. Use `@StateObject` for data dependencies
4. Implement `#Preview` for development

#### Updating Existing Views
1. Locate the appropriate view file
2. Use `@State` for local state
3. Use `@Published` in NoteStore for shared state
4. Follow SwiftUI best practices

### Extending Auto-Tagging

#### Adding New Keywords
```swift
// In NoteStore.swift - generateTags method
let keywords = [
    // ... existing keywords ...
    "newkeyword": "newtag"
]
```

#### Improving Algorithm
1. Replace simple keyword matching
2. Integrate Natural Language framework
3. Add Apple Intelligence APIs
4. Implement machine learning models

### Data Storage Changes

#### Switching from UserDefaults
1. Create new storage protocol
2. Implement concrete storage classes
3. Update NoteStore to use protocol
4. Handle data migration

#### Adding New Storage Features
1. Implement in NoteStore methods
2. Update persistence layer
3. Handle errors gracefully
4. Add appropriate tests

## Testing Strategy

### Unit Tests
Create tests for:
- Note model computed properties
- NoteStore CRUD operations
- Data persistence
- Tag generation logic

### UI Tests
Test:
- Note creation flow
- Note editing flow
- List navigation
- Empty state handling

### Example Test
```swift
func testNoteCreation() {
    let store = NoteStore()
    let note = Note(title: "Test", content: "Content")
    
    store.addNote(note)
    
    XCTAssertEqual(store.notes.count, 1)
    XCTAssertEqual(store.notes.first?.title, "Test")
}
```

## Debugging Tips

### Common Issues

#### Notes Not Persisting
1. Check if `saveNotes()` is called
2. Verify UserDefaults key consistency
3. Check JSON encoding/decoding

#### UI Not Updating
1. Ensure `@Published` properties are used
2. Check `@StateObject` vs `@ObservedObject`
3. Verify state binding

#### Performance Issues
1. Profile with Instruments
2. Check for retain cycles
3. Monitor memory usage
4. Optimize list rendering

### Debug Techniques
```swift
// Add logging to NoteStore
print("Saving \(notes.count) notes")

// Add breakpoints in key methods
// Use Xcode's Memory Graph debugger
// Profile with Time Profiler
```

## Architecture Decisions

### Why MVVM?
- Clean separation of concerns
- Testable business logic
- SwiftUI compatibility
- Scalable architecture

### Why UserDefaults?
- Simple implementation
- Suitable for small datasets
- No external dependencies
- Reliable persistence

### Why Keyword-Based Tagging?
- Demonstrates concept
- No external dependencies
- Easy to understand
- Extensible foundation

## Performance Considerations

### Memory Management
- Use `@StateObject` for data that owns the view
- Use `@ObservedObject` for data passed from parent
- Avoid retain cycles in closures
- Monitor memory usage during development

### UI Performance
- Use `LazyVStack` for large lists
- Implement proper list diffing
- Avoid expensive operations in body
- Use `@ViewBuilder` for complex views

### Data Operations
- Batch save operations when possible
- Use background queues for heavy processing
- Implement proper error handling
- Monitor disk I/O performance

## Future Enhancements

### Short Term (1-2 weeks)
1. Add search functionality
2. Implement note categories
3. Add export capabilities
4. Improve error handling

### Medium Term (1-2 months)
1. Rich text editing
2. Image attachments
3. Better tagging algorithms
4. iCloud synchronization

### Long Term (3-6 months)
1. Apple Intelligence integration
2. Advanced search with filters
3. Collaboration features
4. Multi-platform support

## Best Practices

### Code Style
- Follow Swift naming conventions
- Use meaningful variable names
- Write clear, concise comments
- Organize code with MARK comments

### SwiftUI Patterns
- Keep views small and focused
- Use computed properties for derived data
- Implement proper state management
- Follow iOS design guidelines

### Data Management
- Always persist after modifications
- Handle errors gracefully
- Use proper data types
- Implement data validation

## Troubleshooting

### Build Issues
1. Clean build folder (⌘+Shift+K)
2. Reset simulator
3. Check deployment target
4. Verify Swift version

### Runtime Issues
1. Check console for errors
2. Use breakpoints for debugging
3. Verify data integrity
4. Monitor memory usage

### UI Issues
1. Check state binding
2. Verify view hierarchy
3. Test on different devices
4. Check accessibility

## Resources

### Documentation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [UserDefaults Guide](https://developer.apple.com/documentation/foundation/userdefaults)

### Tools
- Xcode Instruments
- SwiftUI Previews
- Accessibility Inspector
- Memory Graph Debugger

### Community
- Swift Forums
- Stack Overflow
- iOS Developer Community
- Apple Developer Forums 