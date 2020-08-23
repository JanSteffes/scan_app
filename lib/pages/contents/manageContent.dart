import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scan_app/models/ListItem.dart';

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
  static const String _listFilesMethod = "listRequest";
  static const String _mainButtonText = "Zusammenführen";
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
      buildFileNameOption()
    ]);
  }

  /// Method for request to list files from server
  Future sendRequestFileRequest() async {
    setState(() {
      executingAsyncRequest = true;
    });
    try {
      var result =
          await widget.methodChannel.invokeMethod<String>(_listFilesMethod);
      setState(() => {_files = new List<ListItem<String>>()});
      var resultList = result.split(";");
      if (resultList.length > 0) {
        setState(() {
          for (var fileName in resultList) {
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
      showErrorSnackbar("Es muss ein Dateiname angegeben werden");
      return false;
    }
    var selectedFiles = _files.where((element) => element.isSelected);
    if (selectedFiles.length < 2) {
      showErrorSnackbar("Es müssen mindestens 2 Dateien ausgewählt werden");
      return false;
    }
    return true;
  }

  Future successfullExcecutionCallBack() async {
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

  Widget _getListItemTile(BuildContext context, int index) {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        color: _files[index].isSelected ? Colors.red : Colors.white,
        child: ListTile(
            leading: GestureDetector(
                onTap: () {
                  if (_files.any((item) => item.isSelected)) {
                    setState(() {
                      _files[index].isSelected = !_files[index].isSelected;
                    });
                  }
                },
                onLongPress: () {
                  setState(() {
                    _files[index].isSelected = true;
                  });
                },
                child: Text(_files[index].data)),
            trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => showDeleteFileDialog(index))));
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
    );
  }

  @override
  String getMainButtonText() {
    return _mainButtonText;
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
                child: Text("Nein"),
                onPressed: () => Navigator.pop(alertContext),
              ),
              FlatButton(
                  child: Text("Ja"),
                  onPressed: () async => {
                        Navigator.pop(alertContext),
                        await sendNativeCommandRequest(_deleteRequest, {
                          "FileNames": [_files[index].data]
                        })
                      })
            ]); // show the dial
      },
    );
  }
}
