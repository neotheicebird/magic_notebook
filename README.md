# Magic Notes - SwiftUI Note Taking App

A beautiful, intelligent note-taking application built with SwiftUI for iOS and macOS. Magic Notes features smart auto-tagging, metadata tracking, and a clean, intuitive interface.

## Features

### Core Features
- **Universal App**: Runs on both iOS and macOS from a single codebase
- **Clean Interface**: Minimalist design with focus on content
- **Smart Auto-Tagging**: Automatically generates relevant tags based on note content
- **Rich Metadata**: Tracks creation time, edit time, word count, and reading time
- **Local Storage**: All notes are saved locally on your device
- **Empty State**: Beautiful empty state when no notes exist

### User Interface
- **List View**: Shows all notes with preview and metadata
- **Entry View**: Clean editing interface with title and content sections
- **Floating Action Button**: Quick access to create new notes
- **Expandable Metadata**: Tap the info icon to view detailed note information
- **Search and Filter**: Easy navigation through your notes

## Screenshots

*Screenshots would go here when the app is running*

## Getting Started

### Prerequisites
- macOS 14.0 or later
- Xcode 15.0 or later
- iOS 17.0 or later (for iOS devices)

### Installation

1. **Clone or Download the Project**
   ```bash
   git clone <repository-url>
   cd magic_notebook
   ```

2. **Open in Xcode**
   - Open Xcode
   - Select "Open a project or file"
   - Navigate to the project folder and select `MagicNotes.xcodeproj`

3. **Build and Run**
   - Select your target device (iPhone, iPad, or Mac)
   - Press `Cmd + R` to build and run the app

### Project Structure

```
MagicNotes/
├── MagicNotesApp.swift          # Main app entry point
├── ContentView.swift            # Main list view
├── EntryView.swift              # Note creation/editing view
├── Note.swift                   # Note data model
├── NoteStore.swift              # Data management and storage
└── README.md                    # Project documentation
```

## Architecture

### Data Model
- **Note**: Core data structure containing title, content, tags, and metadata
- **NoteStore**: ObservableObject managing all note operations and persistence

### Views
- **ContentView**: Main list view with notes and floating action button
- **EntryView**: Note editing interface with title and content sections
- **NoteRowView**: Individual note display with metadata toggle
- **MetadataView**: Detailed note information display

### Storage
- Uses `UserDefaults` for local persistence
- JSON encoding/decoding for data serialization
- Automatic save on note creation and updates

## Smart Features

### Auto-Tagging System
The app includes a smart tagging system that automatically generates relevant tags based on note content. Currently implemented with keyword matching, but designed to be easily upgraded to use Apple's Natural Language framework or Apple Intelligence APIs.

**Supported Tags:**
- meeting, idea, todo, task, reminder
- important, urgent, project, work, personal
- travel, shopping, health, finance
- education, research, general

### Metadata Tracking
Each note automatically tracks:
- Creation date and time
- Last edited date and time
- Word count
- Estimated reading time
- Generated tags

## Customization

### Adding New Tag Categories
To add new automatic tags, modify the `keywords` dictionary in `NoteStore.swift`:

```swift
let keywords = [
    "your-keyword": "your-tag",
    // ... existing keywords
]
```

### Styling
The app uses SwiftUI's adaptive colors and system fonts. To customize:
- Modify color schemes in individual views
- Update font styles in the respective view files
- Adjust spacing and padding values

## Future Enhancements

### Planned Features
- **Apple Intelligence Integration**: Advanced AI-powered tagging and content analysis
- **iCloud Sync**: Sync notes across all your devices
- **Rich Text Editing**: Support for formatting, lists, and attachments
- **Search Functionality**: Full-text search across all notes
- **Export Options**: Export notes to various formats (PDF, Markdown, etc.)
- **Categories and Folders**: Organize notes into custom categories
- **Themes**: Multiple color themes and appearance options

### Technical Improvements
- **Core Data**: Migrate from UserDefaults to Core Data for better performance
- **CloudKit**: Add cloud synchronization capabilities
- **Widgets**: iOS and macOS widget support
- **Shortcuts**: Siri Shortcuts integration
- **TestFlight**: Prepare for beta testing and App Store distribution

## Development

### Code Style
- Follow Swift and SwiftUI best practices
- Use `// MARK:` comments for code organization
- Implement proper error handling
- Write clear, self-documenting code

### Testing
- Test on multiple iOS devices and screen sizes
- Test on macOS with different window sizes
- Verify persistence across app launches
- Test edge cases (empty notes, long content, etc.)

### Building for Distribution
When ready for TestFlight or App Store:
1. Update version and build numbers
2. Configure App Store Connect
3. Create app icons and screenshots
4. Set up provisioning profiles
5. Archive and upload to App Store Connect

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is open source. Please check the LICENSE file for details.

## Support

If you encounter any issues or have questions:
- Check the GitHub Issues page
- Review the code comments for implementation details
- Test on the iOS Simulator or macOS to debug issues

## Acknowledgments

Built with SwiftUI and leveraging Apple's ecosystem for a native, performant experience across iOS and macOS platforms.