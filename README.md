!! **won't be continued** !!
in favor of [ScanClient](https://github.com/JanSteffes/scan_client) - also a flutter approach but with way more functionality





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

## TODO:

- [x] add PDF Viewer to view scanned pdfs
- [ ]  ~~add more options to edit files (rename, rotate,..)~~
- [ ] ~~overwork views, they're mostly build for functionality, not to look good ;)~~
- [ ] ~~add some other design stuff, like splashscreen, icon, etc etc~~

  
