import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scan_app/models/FileItem.dart';
import 'package:scan_app/models/ListItem.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share/share.dart';

import 'content.dart';

class ManageFilesContent extends Content {
  ManageFilesContent({Key key, MethodChannel methodChannel})
      : super(key: key, methodChannel: methodChannel);

  @override
  _ManageFilesState createState() => _ManageFilesState();
}

class _ManageFilesState extends ContentState<ManageFilesContent> {
  TextEditingController _fileNameTextController = TextEditingController();
  static const String _title = "Dateien verwalten";
  static const String _requestMethod = "mergeRequest";
  static const String _deleteRequest = "deleteRequest";
  static const String _getRequest = "getRequest";
  static const String _listFilesMethod = "listRequest";
  static const String _mainButtonText = "zusammenführen";
  static const String _mainButtonNoFileText =
      "Mindestens 2 Dateien auswählen ( + )";
  static const String _noFileName = "Dateiname angeben!";
  List<ListItem<FileItem>> _files = new List<ListItem<FileItem>>();

  int selectIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => sendRequestFileRequest());
  }

  @override
  Widget buildSpecificContent(BuildContext buildContext) {
    return Column(children: [
      buildRefreshButton(),
      buildFilesListView(),
      buildListViewLegend(),
      buildFileNameOption()
    ]);
  }

  Widget buildListViewLegend() {
    return Row(
      children: [
        Icon(Icons.remove_red_eye),
        Text("Anzeigen"),
        getSpacer(),
        Icon(Icons.add),
        Text("Zusammenführen"),
        getSpacer(),
        Icon(Icons.delete),
        Text("Löschen"),
        getSpacer(),
        Icon(Icons.share),
        Text("Teilen")
      ],
    );
  }

  @override
  getArguments() {
    var selectedFiles = _files
        .where((element) => element.isSelected)
        .map((e) => e.data)
        .toList();
    selectedFiles.sort((f1, f2) => f1.selectIndex.compareTo(f2.selectIndex));
    var selectedFileNames = selectedFiles.map((f) => f.fileName).toList();
    return {
      "FileName": _fileNameTextController.text,
      "FileNames": selectedFileNames
    };
  }

  @override
  String getRequestMethod() {
    return _requestMethod;
  }

  @override
  String getTitle() {
    return _title;
  }

  @override
  bool validateInputs() {
    var resultFileNameValid = _fileNameTextController.text.isNotEmpty;
    if (!resultFileNameValid) {
      showErrorSnackbar(_noFileName);
      return false;
    }
    var selectedFiles = _files.where((element) => element.isSelected);
    if (selectedFiles.length < 2) {
      showErrorSnackbar(_mainButtonNoFileText);
      return false;
    }
    return true;
  }

  Future successfullExcecutionCallBack(dynamic result) async {
    await sendRequestFileRequest();
  }

  buildFilesListView() {
    return Container(
      height: MediaQuery.of(context).size.height / 2,
      width: MediaQuery.of(context).size.width,
      child: _files.length > 0
          ? ListView.builder(
              itemCount: _files.length, itemBuilder: _getListItemTile)
          : Center(child: Text("Keine Dateien gefunden")),
    );
  }

  void selectFile(int index) {
    setState(() {
      _files[index].isSelected = !_files[index].isSelected;
      if (_files[index].isSelected) {
        log("selected file " + _files[index].data.fileName);
        // get selected, get latest index + 1
        _files[index].data.selectIndex = ++selectIndex;
        log("set index to " + selectIndex.toString());
      } else {
        log("deselected file " + _files[index].data.fileName);
        // got deselected, need to decrease all other indexes
        --selectIndex;
        var currentIndex = _files[index].data.selectIndex;
        log("it had index " + currentIndex.toString());
        // get all files that are selected and have bigger selection index than current
        var selectedFiles = _files
            .where((element) =>
                element.isSelected && element.data.selectIndex > currentIndex)
            .toList();
        log("will decrease index of " +
            selectedFiles.length.toString() +
            " files");
        // reversesort by index
        selectedFiles
            .sort((a, b) => b.data.selectIndex.compareTo(a.data.selectIndex));
        for (var selectedFile in selectedFiles) {
          // decrease index by 1
          log("setting index of " +
              selectedFile.data.fileName +
              " from " +
              selectedFile.data.selectIndex.toString() +
              " to " +
              (selectedFile.data.selectIndex - 1).toString());
          selectedFile.data.selectIndex = selectedFile.data.selectIndex - 1;
        }
      }
    });
  }

  Future<File> downloadFile(int index) async {
    var fileItem = _files[index].data;
    var fileName = fileItem.fileName;
    List<int> fileBytes = await sendGetFileRequest(fileName);
    if (fileBytes == null) {
      showErrorSnackbar("Fehler beim Laden der Datei $fileName");
      return null;
    } else {
      // write to file
      // but request permission first
      if (await Permission.storage.request().isGranted) {
        setState(() {
          executingAsyncRequest = true;
        });
        // Either the permission was already granted before or the user just granted it.
        // code of read or write file in external storage (SD card)
        final externalDirectory = await getExternalStorageDirectory();
        var directoryPath = externalDirectory.path + "/scan_app";
        var tempFile = File('$directoryPath/$fileName');
        await Directory(directoryPath).create();
        tempFile.writeAsBytesSync(fileBytes,
            mode: FileMode.writeOnly, flush: true);
        setState(() {
          executingAsyncRequest = false;
        });
        return tempFile;
      }
      setState(() {
        executingAsyncRequest = false;
      });
      return null;
    }
  }

  Future showFile(int index) async {
    var file = await downloadFile(index);
    // open with pdf
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFView(filePath: file.path),
        ));
  }

  Future shareFile(int index) async {
    var file = await downloadFile(index);
    // var result =
    //     await widget.methodChannel.invokeMethod<bool>(_shareMailRequest, {
    //   "FilePaths": [file.path],
    //   "ShareMessage":
    // });
    Share.shareFiles([file.path],
        text: "Datei " + _files[index].data.fileName + " versenden über..");
    // Share.shareFiles([file.path],
    //     text: 'Datei ' + _files[index].data + '  teilen');
  }

  Widget _getListItemTile(BuildContext context, int index) {
    var selected = _files[index].isSelected;
    var children = List<Widget>();
    if (!selected) {
      children.addAll([
        IconButton(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            icon: Icon(Icons.remove_red_eye),
            color: Colors.black,
            onPressed: () => showFile(index)),
        IconButton(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            icon: Icon(Icons.add),
            color: Colors.black,
            onPressed: () => selectFile(index)),
        IconButton(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            icon: Icon(Icons.delete),
            color: Colors.black,
            onPressed: () => showDeleteFileDialog(index)),
        IconButton(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            icon: Icon(Icons.share),
            color: Colors.black,
            onPressed: () => shareFile(index))
      ]);
    } else {
      children.addAll([
        IconButton(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            icon: Icon(Icons.remove),
            color: Colors.black,
            onPressed: () => selectFile(index)),
        Text("Seite " + _files[index].data.selectIndex.toString()),
        SizedBox(width: 10)
      ]);
    }
    return Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        color: selected ? Colors.blue[200] : Colors.white,
        child: Row(children: [
          Expanded(
              flex: 6,
              child: Tooltip(
                  message: _files[index].data.fileName,
                  child: Row(children: [
                    Icon(Icons.picture_as_pdf, color: Colors.black),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text(_files[index].data.fileName,
                            overflow: TextOverflow.ellipsis))
                  ]))),
          Expanded(
              flex: 5,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: children,
                  crossAxisAlignment: CrossAxisAlignment.center))
        ]));
  }

  Widget buildRefreshButton() {
    return OutlineButton(
        onPressed: () async => sendRequestFileRequest(),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [Icon(Icons.refresh), Text("Liste aktualisieren")]));
  }

  Widget buildFileNameOption() {
    return TextField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: 'Dateiname',
      ),
      autocorrect: false,
      controller: _fileNameTextController,
      onChanged: (string) => updateButton(),
    );
  }

  void updateButton() {
    setState(() {});
  }

  @override
  String getMainButtonText() {
    if (_fileNameTextController.text.isEmpty) {
      return _noFileName;
    }
    var selectedFilesCount =
        _files.where((element) => element.isSelected).length;
    return selectedFilesCount < 2
        ? _mainButtonNoFileText
        : selectedFilesCount.toString() + " Dateien " + _mainButtonText;
  }

  showDeleteFileDialog(int index) {
    // set up the buttons
    showDialog(
      context: context,
      builder: (BuildContext alertContext) {
        return AlertDialog(
            title: Text("Datei '" + _files[index].data.fileName + "' löschen"),
            content: Text("Soll die Datei '" +
                _files[index].data.fileName +
                "' wirklich gelöscht werden?"),
            actions: [
              FlatButton(
                  child: Text("Ja"),
                  onPressed: () async => {
                        Navigator.pop(alertContext),
                        await sendNativeCommandRequest(_deleteRequest, {
                          "FileNames": [_files[index].data.fileName]
                        })
                      }),
              FlatButton(
                child: Text("Nein"),
                onPressed: () => Navigator.pop(alertContext),
              ),
            ]); // show the dial
      },
    );
  }

  Future<List<int>> sendGetFileRequest(String fileName) async {
    setState(() {
      executingAsyncRequest = true;
    });
    try {
      var rawResult = await widget.methodChannel
          .invokeMethod<List<int>>(_getRequest, {"FileName": fileName});
      return rawResult;
    } on PlatformException catch (e) {
      Scaffold.of(currentContext).showSnackBar(SnackBar(
          content: Text("Fehler beim Verarbeiten der Anfrage: " + e.message)));
      return null;
    } finally {
      setState(() {
        executingAsyncRequest = false;
      });
    }
  }

  /// Method for request to list files from server
  Future sendRequestFileRequest() async {
    setState(() {
      executingAsyncRequest = true;
      selectIndex = 0;
    });
    try {
      var rawResult = await widget.methodChannel
          .invokeMethod<List<dynamic>>(_listFilesMethod);
      var result = rawResult.map((e) => e.toString()).toList();
      result.sort((e, v) => e.toString().compareTo(v.toString()));
      setState(() => {_files = new List<ListItem<FileItem>>()});
      if (result.length > 0) {
        setState(() {
          for (var fileName in result) {
            _files.add(new ListItem<FileItem>(FileItem(fileName)));
          }
        });
      } else {
        showErrorSnackbar();
      }
    } on PlatformException catch (e) {
      Scaffold.of(currentContext).showSnackBar(SnackBar(
          content: Text("Fehler beim Verarbeiten der Anfrage: " + e.message)));
    } finally {
      setState(() {
        executingAsyncRequest = false;
      });
    }
  }
}
