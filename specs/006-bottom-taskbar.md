# Introduction

The application is shaping well. Now I want to add a bottom toolbar with UI element groups to apply actions.

# High Level Tasks

1. Add a bottom toolbar, standard height, such as one in iOS notes app. We need a toolbar that will fit with the liquid glass standards newly introduced by Apple. Use the App Icons from NucleoAppIcons image set added to the project. Start by adding 4 icons from left
    - folder
    - star-sparkle-1
    - swap-1
    - pen

Technical Details:
    - Use .ultraThinMaterial background for the liquid glass effect
    - Standard iOS toolbar height (~49pt)
    - Safe area aware positioning
    - Icons from your NucleoAppIcons asset catalog

2. Make the pen button replace the Add note + icon placed in the top right corner of list screen

3. Make the star-sparkle-1 replace the stats functionality added in the top left part of the list screen

4. Other 2 icons shouldn't do anything for now.

5. Use a large code-editor icon instead of the "Notes" title on top of the list screen

6. Create a visual summary of the implementation, add to documentation if possible

# Guidelines

1. Always discuss your ideas and ask for explicit ok before making major changes, explain how the changes would affect exiting version
2. Update the version.txt at the end of the changes
3. Feel free to replace implementations, we are still prototyping, no need for migrating existing features to the new implementation