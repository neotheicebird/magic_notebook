# Introduction

We currently have a entry screen with a "< back", "done" buttons and blocks are rendered as seperate UI items with labels such as "Heading" label followed by text input for the heading. We also have a "Add block" link button at the bottom of the document which user can click to add a new block. This is a great prototype implemenation that validates functionality. We want to move towards a more seamless UI/UX experience that is inspired from classical document editors such as Microsoft Word, and modern interfaces such as Notion. Let us make some valuable UI/UX changes now.

# High Level Tasks

1. Entry Screen: 

    A. Add a lemongreen "+" button at the bottom right corner. This button should toggle various editing features such as `undo`, `redo` and any other features such as `bold`, `italics`, `underline` etc which we will introduce in the future. No need to implement any new buttons in this task. 
        - Move the undo, redo, share buttons into a bottom taskbar that shows up when user toggles the + button. When taskbar is shown, show an X button at the right end which when clicked hides the taskbar again.

    B. Hide the block based implementation detail from user: 
        - Show a seamless document editor instead of input fields. The first line is the "Heading" section, which should be empty by default without any placeholder text. 
        - After the heading block is the first empty paragraph block in a new document, again empty by default without any placeholder text. The cursor size in this block should be smaller than the cursor size in Heading section. Set the cursor position to be start of the first block in a new document entry
        - Whenever user makes a consequitive double newline entry create a new block (visually this is how paragraphs are seperated). Visually the user should only see a new paragraph even though we are storing and handling blocks in data logic. No need for any visual cues to user that they are dealing in blocks yet.
        - Make sure to handle logic related to above changes such as, if user deletes the newline characters at the end of a paragraph block, then they mean to merge two paragraphs then append the content of the bottom block top, and delete the bottom block from memory. User should also be able to move cursor at any point in a paragraph block, press return two times and create two paragraph blocks from one, update blocks[] memory as needed.
        - Remove the "Add block" link button
    
    C. Top nav buttons:
        - Instead of "< back" button, simply show a left chevron
        - Instead of "done" button simply show a tick mark icon

2. Stats:
    - Remove the block statistics section
    - Remove buttons like export all documents, clear data etc
    - Simplify the overall dashboard experience, less clutter, more value
    - Change the statistics portal icon, go nuts with choosing an interesting one

# Guidelines

1. Always discuss your ideas and ask for explicit ok before making major changes, explain how the changes would affect exiting version
2. Update the version.txt at the end of the changes
3. Feel free to replace implementations, we are still prototyping, no need for migrating existing features to the new implementation