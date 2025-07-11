# Magic Notes - Setup Guide

This guide will walk you through setting up the Magic Notes SwiftUI application in Xcode from scratch.

## Prerequisites

- **macOS 14.0 or later**
- **Xcode 15.0 or later**
- **Apple Developer Account** (for device testing, optional for simulator)

## Step 1: Create New Xcode Project

1. Open Xcode
2. Select "Create a new Xcode project"
3. Choose **iOS** tab
4. Select **App** template
5. Click **Next**

## Step 2: Configure Project Settings

Fill in the project details:

- **Product Name**: `MagicNotes`
- **Team**: Select your Apple Developer Team (or leave as is)
- **Organization Identifier**: `com.yourname.magicnotes` (replace with your identifier)
- **Bundle Identifier**: Will auto-populate
- **Language**: `Swift`
- **Interface**: `SwiftUI`
- **Use Core Data**: ❌ (Unchecked)
- **Include Tests**: ✅ (Checked, optional)

Click **Next** and choose a location to save your project.

## Step 3: Enable macOS Support

To make this a universal app (iOS + macOS):

1. Select your project in the navigator
2. Select the **MagicNotes** target
3. In the **General** tab, find **Supported Destinations**
4. Click the **+** button and add **macOS**
5. Set the macOS deployment target to **14.0**

## Step 4: Add the Source Files

Replace the default files with our Magic Notes files:

### Delete Default Files
1. Delete `ContentView.swift` (we'll replace it)
2. Keep `MagicNotesApp.swift` but replace its contents

### Add Our Files
Copy the contents from our created files:

1. **MagicNotesApp.swift** - Replace contents with our app entry point
2. **ContentView.swift** - Add our main list view
3. **EntryView.swift** - Add our note editing view
4. **Note.swift** - Add our data model
5. **NoteStore.swift** - Add our data management class

### File Organization (Optional)
Create groups in Xcode to organize files:
- Right-click in project navigator
- Select "New Group"
- Create groups like: `Models`, `Views`, `Stores`

## Step 5: Configure Info.plist

Update the Info.plist with our configuration:

1. Open `Info.plist` in Xcode
2. Replace contents with our Info.plist content
3. Or manually add these keys:
   - `CFBundleDisplayName`: "Magic Notes"
   - Update supported orientations as needed

## Step 6: Set Deployment Targets

1. Select your project in the navigator
2. Select the **MagicNotes** target
3. In the **General** tab:
   - Set **iOS Deployment Target** to **17.0**
   - Set **macOS Deployment Target** to **14.0**

## Step 7: Configure App Icons (Optional)

1. In the navigator, find `Assets.xcassets`
2. Select `AppIcon`
3. Add app icons for different sizes (you can use placeholder icons for now)

## Step 8: Build and Run

### For iOS Simulator:
1. Select an iOS simulator from the scheme selector
2. Press `Cmd + R` to build and run

### For macOS:
1. Select "My Mac" from the scheme selector
2. Press `Cmd + R` to build and run

### For iOS Device:
1. Connect your iPhone/iPad
2. Select your device from the scheme selector
3. You may need to sign the app with your Apple ID
4. Press `Cmd + R` to build and run

## Step 9: Test the App

Once the app is running, test these features:

1. **Empty State**: Should show "No Notes Yet" message
2. **Create Note**: Tap the blue pencil button
3. **Add Content**: Type in the content area
4. **Save Note**: Tap "Done" to save
5. **View Notes**: Return to main list to see your note
6. **Edit Note**: Tap on an existing note to edit
7. **View Metadata**: Tap the "i" icon on any note
8. **Auto-Tags**: Notes should get automatic tags based on content

## Troubleshooting

### Common Issues:

1. **Build Errors**: Make sure all files are added to the target
2. **Missing Imports**: Ensure all files import necessary frameworks
3. **macOS Build Issues**: Check macOS deployment target settings
4. **Simulator Issues**: Try resetting the simulator

### File Structure Check:
Your project should have these files:
```
MagicNotes/
├── MagicNotesApp.swift
├── ContentView.swift
├── EntryView.swift
├── Note.swift
├── NoteStore.swift
├── Assets.xcassets/
│   └── AppIcon.appiconset/
├── Info.plist
└── Preview Content/
    └── Preview Assets.xcassets/
```

## Next Steps

### For Development:
1. **Version Control**: Initialize git repository
2. **Documentation**: Add code comments
3. **Testing**: Write unit tests
4. **Performance**: Profile and optimize

### For Distribution:
1. **App Store Connect**: Set up app listing
2. **TestFlight**: Configure for beta testing
3. **Screenshots**: Create App Store screenshots
4. **Metadata**: Prepare app description and keywords

## Advanced Features

### Future Enhancements:
- **Apple Intelligence**: Upgrade tagging system
- **iCloud Sync**: Add CloudKit integration
- **Rich Text**: Implement text formatting
- **Search**: Add full-text search capabilities

### Code Improvements:
- **Core Data**: Migrate from UserDefaults
- **Unit Tests**: Add comprehensive test coverage
- **UI Tests**: Add interface testing
- **Accessibility**: Improve VoiceOver support

## Support

If you encounter issues:
1. Check the console for error messages
2. Verify all files are properly added to the target
3. Ensure deployment targets are set correctly
4. Test on both iOS and macOS if possible

## Success! 🎉

You now have a fully functional Magic Notes app running on both iOS and macOS! The app includes:
- ✅ Note creation and editing
- ✅ Auto-tagging system
- ✅ Metadata tracking
- ✅ Local storage
- ✅ Beautiful UI with empty states
- ✅ Cross-platform compatibility

Happy note-taking! 📝 