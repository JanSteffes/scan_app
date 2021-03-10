# scan_app

App to communicate with [ScanServer](https://github.com/JanSteffes/ScanServer)

## Getting Started

Contains 2 tabs:
* Scan
* Manage Files

## Scan

Scan file with a selectable quality and give it a name. Will use <filename>_<count> as fileName if there is already a file with that name.
Example: file "test.pdf" exists already and a new scan is requested with that name. The name of the newly scanned file will therefore be change to "test_0.pdf", "test_1.pdf" and so on accordingly
  
## Manage Files

Displays a list of files of the current directory (e.g. current date - all files from today).
There, files can be deleted, shown, or merged together. Naming of resulting files is like in Scan.


## Overview

### AppBarActions:

<img src="https://github.com/JanSteffes/scan_app/blob/develop/readme_images/AppBar_Actions.png?raw=true" alt="Available Functions in AppBar" width="13%"></img>

#### AppInfo

<img src="https://github.com/JanSteffes/scan_app/blob/develop/readme_images/AppBar_Actions_AppInfo.png?raw=true" alt="Information about app" width="13%"></img>

### ScanMenu:

<img src="https://github.com/JanSteffes/scan_app/blob/develop/readme_images/ScanMenu.png?raw=true" alt="Menu to scan new files" width="13%"></img> 

### FileMenu:

#### Swipe Actions

##### Right
<img src="https://github.com/JanSteffes/scan_app/blob/develop/readme_images/FileMenu_SlideActions_Right.png?raw=true" alt="Additional actions by swipe to the right" width="13%"></img> 


##### Left

<img src="https://github.com/JanSteffes/scan_app/blob/develop/readme_images/FileMenu_SlideActions_Left.png?raw=true" alt="AdditionalActions by swipe to left" width="13%"></img> 

#### Merge Files
<img src="https://github.com/JanSteffes/scan_app/blob/develop/readme_images/FileMenu_MergeReady.png?raw=true" alt="Merge ready" width="13%"></img> 

## TODO:

- [x] add PDF Viewer to view scanned pdfs
- [x] overwork views, they're mostly build for functionality, not to look good ;)
- [x] add some other design stuff, like splashscreen, icon, etc etc
- [ ] add more options to edit files (rename, rotate,..)
- [ ] further work on update process: show progress of downloaded apk file
- [ ] further works on design (selected folder still no white backgroud, missing description/label)
