import 'package:async_builder/async_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scan_app/models/datamodels/selected_files.dart';
import 'package:scan_app/models/listmodels/slideable/slideable_action.dart';
import 'package:scan_app/models/notifications/slidable_action_notification.dart';
import 'package:scan_app/models/notifications/slideable_selectaction_notification.dart';
import 'package:scan_app/widgets/file_List/files_list.dart';

class FolderFileView extends StatefulWidget {
  final List<String> _folders;
  final Future<List<String>> Function(String folderName) _loadFilesFunction;
  final Map<SlideableAction, Function(String)> _slideActionFuctionsMapping;

  FolderFileView(
      this._folders, this._loadFilesFunction, this._slideActionFuctionsMapping,
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
  SelectedFiles _selectedFilesRef;
  SelectedFolder _selectedFolderRef;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _selectedFilesRef = Provider.of<SelectedFiles>(context, listen: false);
    _selectedFolderRef = Provider.of<SelectedFolder>(context, listen: false);
    return NotificationListener<SlideableActionNotification>(
        child: Consumer<SelectedFolder>(
            builder: (consumerContext, selectedFolder, child) {
          var selectedFolderValue = selectedFolder.getSelectedFolder();
          return Column(children: [
            DropdownButton<String>(
                value: selectedFolderValue,
                items: widget._folders
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                      value: value, child: Text(value));
                }).toList(),
                onChanged: updateFolder),
            buildFilesListView(selectedFolderValue),
          ]);
        }),
        onNotification: (notification) =>
            handleSlideableActionNotification(notification));
  }

  handleSlideableActionNotification(SlideableActionNotification notification) {
    if (notification is SlideableSelectActionNotification) {
      if (notification.isSelectAction) {
        _selectedFilesRef.addFile(notification.fileName);
      } else {
        _selectedFilesRef.removeFile(notification.fileName);
      }
    }
  }

  void updateFolder(String newValue) {
    _selectedFolderRef.setFolder(newValue);
    _selectedFilesRef.clearFiles();
  }

  Widget buildFilesListView(String selectedFolder) {
    return AsyncBuilder<List<String>>(
        future: widget._loadFilesFunction.call(selectedFolder),
        waiting: (context) => CircularProgressIndicator(),
        builder: (context, List<String> data) {
          return FilesList(data, widget._slideActionFuctionsMapping);
        },
        error: (context, error, stackTrace) =>
            Text("Fehler", style: TextStyle(color: Colors.red)));
  }
}
