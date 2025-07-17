# Magic Notes App Documentation

## Overview

Magic Notes is a SwiftUI-based note-taking application for iOS that features intelligent auto-tagging capabilities. The app provides a clean, intuitive interface for creating, editing, and organizing notes with metadata-rich features.

## Key Features

- **Note Creation & Editing**: Create and modify notes with titles and content
- **Smart Auto-Tagging**: Automatic tag generation based on note content using keyword matching
- **Rich Metadata**: Word count, estimated reading time, creation/edit timestamps
- **Persistent Storage**: Notes are saved using UserDefaults with JSON encoding
- **Beautiful UI**: Modern SwiftUI interface with empty states and floating action buttons
- **Note Management**: Delete notes with swipe gestures, view detailed metadata

## Architecture

The app follows the **MVVM (Model-View-ViewModel) pattern** with SwiftUI:

- **Model**: `Note.swift` - Data structure for notes
- **ViewModel**: `NoteStore.swift` - Data management and business logic
- **Views**: `ContentView.swift`, `EntryView.swift` - UI components

## Project Structure

```
magicnote/
├── magicnote/
│   ├── magicnoteApp.swift      # App entry point
│   ├── Note.swift              # Note data model
│   ├── NoteStore.swift         # Data management & auto-tagging
│   ├── ContentView.swift       # Main list view
│   └── EntryView.swift         # Note creation/editing view
├── magicnoteTests/             # Unit tests
└── magicnoteUITests/           # UI tests
```

## Getting Started

1. Open `magicnote.xcodeproj` in Xcode
2. Select an iOS simulator or device
3. Build and run the project (⌘+R)

## Documentation Contents

- [Architecture Overview](./architecture.md) - Detailed app architecture explanation
- [Data Models](./data-models.md) - Note model and data structures
- [User Interface](./user-interface.md) - SwiftUI views and components
- [Auto-Tagging System](./auto-tagging.md) - Smart tagging implementation
- [Data Persistence](./data-persistence.md) - Storage and retrieval mechanisms
- [Development Guide](./development-guide.md) - Practical guide for developers

## Development Notes

- **SwiftUI Version**: Compatible with iOS 14+
- **Data Storage**: UserDefaults with JSON encoding
- **State Management**: ObservableObject with @Published properties
- **UI Pattern**: Navigation-based with sheet presentations
- **Async Operations**: Simple DispatchQueue for tag generation simulation

## Future Enhancements

The codebase is designed to be extensible for future features:
- Integration with Apple Intelligence APIs
- Advanced Natural Language Processing for better tagging
- iCloud synchronization
- Rich text editing
- Note categories and folders
- Search functionality 