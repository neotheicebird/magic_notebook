# Architecture Overview

## Design Pattern: MVVM with SwiftUI + Block-Based Document System

The Magic Notes app follows the **Model-View-ViewModel (MVVM)** architectural pattern with a sophisticated block-based document system, providing clean separation of concerns and excellent scalability.

### Architecture Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Views       │    │   ViewModels    │    │     Models      │
│                 │    │                 │    │                 │
│  ContentView    │◄──►│ DocumentStore   │◄──►│   Document      │
│DocumentEditorView│    │                 │    │ DocumentBlock   │
│DocumentRowView  │    │ (ObservableObject) │    │ (FileDocument)  │
│BlockEditorView  │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## App Entry Point

**File**: `magicnoteApp.swift`

```swift
@main
struct MagicNotesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Key Points**:
- Uses SwiftUI's `@main` attribute for app entry
- Simple WindowGroup with ContentView as root
- Cross-platform consideration with macOS window styling

## Block-Based Document System

### Core Architecture Principles

1. **Modular Content**: Documents are composed of individual blocks (heading, paragraph)
2. **FileDocument Protocol**: Each document is a JSON file with comprehensive metadata
3. **Cursor Tracking**: Precise cursor position management for seamless editing
4. **Version Control**: UUID-based versioning for document evolution tracking

### Document Structure

```
Document
├── Metadata (id, version, timestamps, author, active state)
├── Blocks Array
│   ├── DocumentBlock (heading)
│   ├── DocumentBlock (paragraph)
│   └── DocumentBlock (paragraph)
├── Cursor Position (blockId, position)
└── Auto-generated Tags
```

## State Management

### ObservableObject Pattern

The app uses SwiftUI's reactive state management through `@StateObject` and `@Published` properties:

```swift
class DocumentStore: ObservableObject {
    @Published var documents: [Document] = []
    // ... file management properties
}
```

**In Views**:
```swift
struct ContentView: View {
    @StateObject private var noteStore = NoteStore()
    // View automatically updates when notes change
}
```

### State Flow

```
User Action → View State Change → ViewModel Update → Model Update → View Refresh
```

## Data Flow

### Note Creation Flow
1. User taps floating action button
2. `ContentView` presents `EntryView` as sheet
3. User enters note content
4. `EntryView` calls `noteStore.addNote()`
5. `NoteStore` saves note and triggers auto-tagging
6. UI automatically updates via `@Published` property

### Note Editing Flow
1. User taps note row
2. `ContentView` passes selected note to `EntryView`
3. User modifies content
4. `EntryView` calls `noteStore.updateNote()`
5. `NoteStore` updates note and metadata
6. UI reflects changes automatically

## View Hierarchy

```
NavigationView (ContentView)
├── List (Notes)
│   └── NoteRowView (for each note)
│       └── MetadataView (expandable)
├── EmptyStateView (when no notes)
└── FloatingActionButton
```

## Memory Management

- **Automatic Reference Counting (ARC)**: Swift's automatic memory management
- **Weak/Strong References**: Proper closure handling in async operations
- **ObservableObject**: Retained by SwiftUI view lifecycle

## Error Handling

The app implements graceful error handling:

```swift
private func saveNotes() {
    do {
        let data = try JSONEncoder().encode(notes)
        userDefaults.set(data, forKey: notesKey)
    } catch {
        print("Failed to save notes: \(error.localizedDescription)")
    }
}
```

## Performance Considerations

1. **Lazy Loading**: List views only render visible items
2. **Efficient Updates**: @Published only triggers necessary re-renders
3. **Background Processing**: Tag generation happens asynchronously
4. **Memory Efficient**: UserDefaults for small data sets

## Threading Model

- **Main Thread**: All UI updates and SwiftUI state changes
- **Background Queue**: Tag generation simulation
- **Async Operations**: Properly dispatched back to main queue

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    completion(tags)
}
```

## Scalability Notes

The current architecture supports future enhancements:
- **Dependency Injection**: Easy to mock NoteStore for testing
- **Protocol-Based**: Can abstract storage layer
- **Modular Views**: Components can be easily extended
- **Async/Await**: Ready for modern Swift concurrency 