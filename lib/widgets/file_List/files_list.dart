import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:scan_app/models/listmodels/file_item.dart';
import 'package:scan_app/models/listmodels/list_item.dart';
import 'package:scan_app/models/listmodels/slideable/slideable_action.dart';
import 'package:scan_app/models/listmodels/slideable_widget.dart';
import 'package:scan_app/models/notifications/slideable_selectaction_notification.dart';

class FilesList extends StatefulWidget {
  final List<String> _fileNames;
  final Map<SlideableAction, Function(String)> _slideActionFuctionsMapping;

  FilesList(this._fileNames, this._slideActionFuctionsMapping, {Key key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _FilesListState(_fileNames);
}

class _FilesListState<FileList> extends State<FilesList> {
  /// list of files
  List<ListItem<FileItem>> _listItems = List<ListItem<FileItem>>();
  SlidableController _slideableController = SlidableController();

  /// index for files to merge, e.g. next selected file will get this index
  int nextSelectedFileIndex = 0;

  _FilesListState(List<String> _fileNames) {
    _listItems = _fileNames.map((e) => ListItem(FileItem(e))).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
          height: MediaQuery.of(context).size.height * 3 / 7,
          width: MediaQuery.of(context).size.width,
          child: _listItems.length > 0
              ? Scrollbar(
                  child: ListView.builder(
                      itemCount: _listItems.length,
                      itemBuilder: buildListItemTile),
                )
              : Center(child: Text("Keine Dateien gefunden"))),
      // RaisedButton(
      //     onPressed: null,
      //     child: Row(
      //         mainAxisAlignment: MainAxisAlignment.center,
      //         mainAxisSize: MainAxisSize.min,
      //         children: [
      //           Icon(Icons.refresh),
      //           Text("Dateiliste aktualisieren")
      //         ]))
    ]);
  }

  Widget buildListItemTile(BuildContext context, int index) {
    var fileTile = _listItems[index];
    var selected = fileTile.isSelected;
    Map<String, dynamic> buildFunctionArgs = {
      "fileTile": fileTile,
      "index": index
    };
    if (!selected) {
      return SlidableWidget(
          childBuildFunction: buildItemInfo,
          childBuildFunctionArgs: buildFunctionArgs,
          index: index,
          handleSlideActionTap: handleSlideAction,
          slidableController: _slideableController);
    } else {
      return buildItemInfo(context, buildFunctionArgs);
    }
  }

  Widget buildItemInfo(BuildContext listItemBuildContext, dynamic arguments) {
    ListItem<FileItem> fileTile = arguments["fileTile"];
    int index = arguments["index"];
    var selected = fileTile.isSelected;
    var fileItem = fileTile.data;
    var fileName = fileItem.fileName;

    var rowChildren = List<Widget>();
    var fileInfoChild = Expanded(
        flex: 5,
        child: Tooltip(
            message: fileName,
            child: Row(children: [
              Icon(Icons.picture_as_pdf, color: Colors.black),
              SizedBox(width: 10),
              Expanded(
                  child: Text(fileName = fileName,
                      overflow: TextOverflow.ellipsis))
            ])));
    rowChildren.add(fileInfoChild);
    if (selected) {
      var pageText = "Seite " + fileItem.selectIndex.toString();
      var deselectChild = Expanded(
          flex: 2,
          child: Row(children: [
            Text(pageText),
            IconButton(
                icon: Icon(Icons.remove), onPressed: () => selectFile(index))
          ]));
      rowChildren.add(deselectChild);
    } else {
      var currentState = Slidable.of(listItemBuildContext);
      var isSlid = _slideableController.activeState == currentState;
      var showSlide = IconButton(
          icon: Icon(isSlid ? Icons.close : Icons.arrow_forward),
          onPressed: () => isSlid
              ? currentState.close()
              : currentState.open(actionType: SlideActionType.secondary));
      rowChildren.add(showSlide);
    }
    var itemInfo = Container(
        padding: EdgeInsets.all(5),
        decoration:
            BoxDecoration(color: selected ? Colors.blue[200] : Colors.white),
        child: Row(
            children: rowChildren,
            crossAxisAlignment: CrossAxisAlignment.center));
    return itemInfo;
  }

  void handleSlideAction(SlideableAction slideAction, int index) {
    switch (slideAction) {
      case SlideableAction.see:
      case SlideableAction.share:
        widget._slideActionFuctionsMapping[slideAction]
            .call(_listItems[index].data.fileName);
        break;
      case SlideableAction.delete:
        showDeleteFileDialog(_listItems[index].data.fileName);
        break;
      case SlideableAction.selectForMerge:
        selectFile(index);
        break;
    }
  }

  showDeleteFileDialog(String fileName) {
    // set up the buttons
    showDialog(
      context: context,
      builder: (BuildContext alertContext) {
        return AlertDialog(
            title: Text("Datei '$fileName' löschen"),
            content:
                Text("Soll die Datei '$fileName' wirklich gelöscht werden?"),
            actions: [
              FlatButton(
                  child: Text("Ja"),
                  onPressed: () async => {
                        Navigator.pop(alertContext),
                        widget
                            ._slideActionFuctionsMapping[SlideableAction.delete]
                            .call(fileName),
                        setState(() => {
                              _listItems.removeWhere((element) =>
                                  element.data.fileName == fileName)
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

  void selectFile(int index) {
    var isSelectAction = !_listItems[index].isSelected;
    setState(() {
      _listItems[index].isSelected = !_listItems[index].isSelected;
      if (_listItems[index].isSelected) {
        //_log("selected file " + _files[index].data.fileName);
        // get selected, get latest index + 1
        _listItems[index].data.selectIndex = ++nextSelectedFileIndex;
        //_log("set index to " + selectIndex.toString());
      } else {
        //_log("deselected file " + _files[index].data.fileName);
        // got deselected, need to decrease all other indexes
        --nextSelectedFileIndex;
        var currentIndex = _listItems[index].data.selectIndex;
        //_log("it had index " + currentIndex.toString());
        // get all files that are selected and have bigger selection index than current
        var selectedFiles = _listItems
            .where((element) =>
                element.isSelected && element.data.selectIndex > currentIndex)
            .toList();
        //_log("will decrease index of " +
        //    selectedFiles.length.toString() +
        //    " files");
        // reversesort by index
        selectedFiles
            .sort((a, b) => b.data.selectIndex.compareTo(a.data.selectIndex));
        for (var selectedFile in selectedFiles) {
          // decrease index by 1
          //  _log("setting index of " +
          //      selectedFile.data.fileName +
          //      " from " +
          //      selectedFile.data.selectIndex.toString() +
          //      " to " +
          //      (selectedFile.data.selectIndex - 1).toString());
          selectedFile.data.selectIndex = selectedFile.data.selectIndex - 1;
        }
      }
    });
    SlideableSelectActionNotification(SlideableAction.selectForMerge,
        isSelectAction, _listItems[index].data.fileName)
      ..dispatch(context);
  }
}
