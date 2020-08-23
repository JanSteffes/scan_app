import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scan_app/models/ListItem.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

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
  List<ListItem<String>> _files = new List<ListItem<String>>();

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
        Text("Löschen")
      ],
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
    });
    try {
      var rawResult = await widget.methodChannel
          .invokeMethod<List<dynamic>>(_listFilesMethod);
      var result = rawResult.map((e) => e.toString()).toList();
      result.sort((e, v) => e.toString().compareTo(v.toString()));
      setState(() => {_files = new List<ListItem<String>>()});
      if (result.length > 0) {
        setState(() {
          for (var fileName in result) {
            _files.add(new ListItem<String>(fileName));
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

  @override
  getArguments() {
    return {
      "FileName": _fileNameTextController.text,
      "FileNames": _files
          .where((element) => element.isSelected)
          .map((e) => e.data)
          .toList()
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
    });
  }

  Future showFile(int index) async {
    var fileName = _files[index].data;
    List<int> fileBytes = await sendGetFileRequest(fileName);
    if (fileBytes == null) {
      showErrorSnackbar("Fehler beim Laden der Datei $fileName");
      return;
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
        // open with pdf
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFView(filePath: tempFile.path),
            ));
        setState(() {
          executingAsyncRequest = false;
        });
      }
    }
  }

  Widget _getListItemTile(BuildContext context, int index) {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        color: _files[index].isSelected ? Colors.blue[200] : Colors.white,
        child: ListTile(
            leading: Icon(Icons.picture_as_pdf,
                color: _files[index].isSelected ? null : Colors.black),
            title: Text(_files[index].data),
            trailing: Wrap(children: [
              IconButton(
                  icon: Icon(Icons.remove_red_eye),
                  color: _files[index].isSelected ? null : Colors.black,
                  onPressed: () =>
                      _files[index].isSelected ? null : showFile(index)),
              IconButton(
                  icon:
                      Icon(_files[index].isSelected ? Icons.remove : Icons.add),
                  color: _files[index].isSelected ? null : Colors.black,
                  onPressed: () => selectFile(index)),
              IconButton(
                  icon: Icon(Icons.delete),
                  color: _files[index].isSelected ? null : Colors.black,
                  onPressed: () => _files[index].isSelected
                      ? null
                      : showDeleteFileDialog(index))
            ])));
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
            title: Text("Datei '" + _files[index].data + "' löschen"),
            content: Text("Soll die Datei '" +
                _files[index].data +
                "' wirklich gelöscht werden?"),
            actions: [
              FlatButton(
                  child: Text("Ja"),
                  onPressed: () async => {
                        Navigator.pop(alertContext),
                        await sendNativeCommandRequest(_deleteRequest, {
                          "FileNames": [_files[index].data]
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
}
