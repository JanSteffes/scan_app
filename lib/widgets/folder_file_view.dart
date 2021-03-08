import 'package:async_builder/async_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scan_app/models/listmodels/slideable/slideable_action.dart';
import 'package:scan_app/widgets/file_list_controller.dart';
import 'package:scan_app/widgets/files_list.dart';

class FolderFileView extends StatefulWidget {
  final FileListController _fileListController;
  final List<String> _folders;
  final Future<List<String>> Function(String folderName) _loadFilesFunction;
  final Map<SlideableAction, Function(String, String)>
      _slideActionFuctionsMapping;

  FolderFileView(this._fileListController, this._folders,
      this._loadFilesFunction, this._slideActionFuctionsMapping,
      {Key key})
      : super(key: key) {
    SlideableAction.values
        .where((v) => v.needsCallbackFunction)
        .forEach((element) => {
              if (!_slideActionFuctionsMapping.containsKey(element))
                {throw Exception("Missing callback for $element!")}
            });
  }

  @override
  State<StatefulWidget> createState() => _FolderFileViewState();
}

class _FolderFileViewState extends State<FolderFileView> {
  _FolderFileViewState();
  Future<List<String>> loadFilesFuture;

  @override
  void initState() {
    super.initState();
    widget._fileListController.folderName =
        widget._fileListController.folderName ?? widget._folders.first;
    loadFilesFuture =
        widget._loadFilesFunction.call(widget._fileListController.folderName);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      DropdownButton<String>(
          value: widget._fileListController.folderName,
          items: widget._folders.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (newValue) =>
              setState(() => widget._fileListController.setFolder(newValue))),
      buildFilesListView(),
    ]);
  }

  Widget buildFilesListView() {
    return AsyncBuilder<List<String>>(
        future: widget._loadFilesFunction
            .call(widget._fileListController.folderName),
        waiting: (context) => CircularProgressIndicator(),
        builder: (context, List<String> data) {
          return FilesList(data, widget._fileListController,
              widget._slideActionFuctionsMapping);
        },
        error: (context, error, stackTrace) =>
            Text("Fehler", style: TextStyle(color: Colors.red)));
  }
}
