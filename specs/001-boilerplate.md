# Introduction

Magic Notes is a note taking application which users can use like a scribble pad where they can quickly pour in their thoughts and jot down ideas. The app with its smart background processes and LLM powered AI eye for details, picks up details which makes life easier for the user. For example, when users add in some date or time in context of an event, the app might put an action in pipeline for a calendar addition, once the user completes their entry, this action would be confirmed with the user. Similarly, there are so many actions such as auto-tagging, auto-titling, that can be created, sky is the limit.  

# Goal

I want to build a note taking application for iOS and Mac OS from a single source code. I am using cursor IDE on Apple Silicon for development, but I have access to xcode installed in this Macbook air M2 chip. I have a device emulator installed through xcode to test on various ios devices. Please come up with a comprehensive tutorial with as many steps as needed to start with Swift + Swift UI and end up with a simple note taking app that can run on both ios and mac os devices. Keep in mind that later I would like to build the app and distribute using test flight. 

# High Level Tasks

1. List view:
    a. Create a list view with list of note entries made as a list or show empty in case no entries are made. 
    b. This view must have an "pencil" or similar icon at the bottom centre which when clicked opens a new entry using the Entry view described below. 
    c. Click on any existing entry must open the entry in edit mode
    

2. Entry view:
    a. The entry page must be simple, with mainly 3 sections namely Top menu, Title, and Content. The cursor must by default be positioned in the first line of the content.
    b. The title should have a slightly different background color in comparison to content area. The title by default must be empty, but user must be able to click and edit it if needed. The idea in future versions is to automatically find a title by default which users can override. This helps users focus on content and not on titling an entry
    c. Add a "back" buttom with a back chevron to the top left corner which takes the user back to the list view. Save latest state of entry before moving to list view
    d. After editing an entry in entry view, user must be able to click "done" on top right corner to save an entry and move to list view
    e. The entries must be saved locally on device for this version

3. Smart Actions: smart actions are created or added to pipeline as user creates an entry. An example of an action could be "tag-this-entry", which when performed adds hash tags to an entry, helping in grouping entries. For this version, we only need one action to be implemented as a part of experimental startup.

    a. Please use apple intelligence through their APIs or SDKs to create one or more tags for each entry made by the user and add these tags as #<tag-name> in metadata related to entry. 
    b. On the list view, add an "i" info icon to right corner of each item, which when clicked expands item downwards and shows metadata, such as create time, last edited, tags attached, number of words, time to read and any other standard metadata

Please implement these tasks, good luck. As you implement the tasks, explain what you are doing briefly. Assume the developer doesn't know anything about swift UI.