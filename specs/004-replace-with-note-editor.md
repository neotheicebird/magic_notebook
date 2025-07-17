# Introduction

We have a working swiftUI based app which has a notes list view, a create new entry button, an entry editing view and autotagging feature. This is great for a first version. Let us add some feature upgrades.

# High Level Tasks

1. Entry view: 
    - Remove title and content as two separate inputs. We will be adding a document editor input instead as described below.
    - use FileDocument protocol and save the content of the document in JSON format as .json files. We will be adding many blocktypes in future, for now let us define two block types a Heading block and a Paragraph block. By default let every document created have these two blocks starting with a Heading block with empty content.
    - Let the JSON structure be simple for now, say a document list with objects. Each object can have props like blockType and content props. The json files could also have other parent props along with document list such as createdAt, lastEditedAt, author, id (uuid), version (uuid), active (false if deleted)
    - Update the storage logic to deal with .json files
    - Right now the entry screen slides from bottom when creating a new document or editing existing one, instead I would like it to be a new screen which takes all space just like the notes list screen
    - Let the top left button say "< Back" and the top right button say "Done"
    - make sure the cursor starts with the first empty paragraph block when user creates a new entry, and the last block in the file when user edits existing note. This might mean we track the cursor position in the note .json file along with other parent attributes

2. Create New Entry Button:
    - Move this button to the top right corner on the notes list view.
    - Instead of the floating button with a circular background, simply use an + icon, make it lemon green, large font, right aligned next to the "Notes" title

# Low Level Tasks

1. Add and maintain a version log and a latest version.txt file. Use standard versioning protocols. Ask if you want me to choose from options.
2. Prepare a git commit message at the end and show the consise message in the AI Pane
3. Update docs/ with changes you have made. Make notes like a junior developer would need to understand the implemenation. 
4. Remove .swift files from outside the magicnote/ folder

# Guidelines

1. Always discuss your ideas and ask for explicit ok before making major changes, explain how the changes would affect exiting version
2. Update the version.txt at the end of the changes
3. Feel free to replace implementations, we are still prototyping, no need for migrating existing features to the new implementation