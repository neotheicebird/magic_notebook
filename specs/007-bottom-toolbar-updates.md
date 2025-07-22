# Introduction

The bottom toolbar looks amazing. The UI needs some polish though.

# Tasks

1. Show toolbar in both list screen and entry screen. In the entry screen the bottom toolbar should show different icons. Here is the list I would like from left:
    - slider on the left end
    - pen on the right end

2. Entry screen toolbar:
    - Clicking on slider should add a new toolbar, two times the height of bottom toolbar, on top of the bottom toolbar. This new toolbar will house various icons, each with custom functionality which will be implemented later. For now, add any unused icons from assets.     
    - When this toolbar is open, use slider-1 icon, which is colored indicating open toolbar 
    - When the user starts typing or scrolling down, hide the bottom toolbar. If possible, add an animation to move the toolbar out of screen by going down.
    - When user scrolls up the bottom toolbar should be shown again, if possible animate the toolbar coming into screen

3. List screen:
    - When user starts scrolling down hide the bottom toolbar. If possible, add an animation to move the toolbar out of screen by going down.
    - When user scrolls up the bottom toolbar should be shown again, if possible animate the toolbar coming into screen.

4. Left align the large code-editor icon and add a title such as "Entries", remove padding between the title and search input

5. Update documentation with brief notes on the design choices and implementation details. Create a visual summary of the implementation, add to documentation if that feels simpler.

# Guidelines

1. Always discuss your ideas and ask for explicit ok before making major changes, explain how the changes would affect exiting version
2. Update the version.txt at the end of the changes
3. Feel free to replace implementations, we are still prototyping, no need for migrating existing features to the new implementation