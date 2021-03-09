import 'dart:io';

import 'package:async_builder/async_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:scan_app/helper/network_helper.dart';
import 'package:scan_app/models/datamodels/selected_files.dart';
import 'package:scan_app/models/enums/snackbar_type.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:scan_app/models/listmodels/slideable/slideable_action.dart';
import 'package:scan_app/models/notifications/snackbar_notification.dart';
import 'package:scan_app/widgets/file_List/folder_file_view.dart';
import 'package:scan_app/widgets/merge_view/merge_view.dart';
import 'package:share/share.dart';
import 'package:path/path.dart' as p;

class ManageFilesContent extends StatefulWidget {
  ManageFilesContent({Key key}) : super(key: key);

  @override
  _ManageFilesState createState() => _ManageFilesState();
}

class _ManageFilesState extends State<ManageFilesContent> {
  static const _methodChannel =
      const MethodChannel('flutter.native/scanHelper');
  Future _folderLoadFuture;

  TextEditingController _fileNameTextController = TextEditingController();

  SelectedFolder _selectedFolderRef;
  SelectedFiles _selectedFilesRef;

  @override
  void initState() {
    super.initState();
    _folderLoadFuture = loadFolders();
  }

  @override
  void dispose() {
    _selectedFilesRef.clearFiles(true);
    super.dispose();
  }

  @override
  Widget build(BuildContext buildContext) {
    _selectedFolderRef = Provider.of<SelectedFolder>(context, listen: false);
    _selectedFilesRef = Provider.of<SelectedFiles>(context, listen: false);
    return Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      buildFolderSelection(),
      SizedBox(height: 10),
      MergeView(mergeFiles, _fileNameTextController)
    ]);
  }

  Widget buildFolderSelection() {
    return AsyncBuilder<List<String>>(
        future: _folderLoadFuture,
        waiting: (context) => CircularProgressIndicator(),
        builder: (context, List<String> data) {
          var currentFolder = _selectedFolderRef.getSelectedFolder();
          if (currentFolder == null || !data.contains(currentFolder)) {
            _selectedFolderRef.setFolder(data.first, true);
          }
          return FolderFileView(data, loadFiles, {
            SlideableAction.see: showFile,
            SlideableAction.delete: deleteFile,
            SlideableAction.share: shareFile
          });
        },
        error: (context, error, stacktrace) => Text(
            "Fehler bei Anfrage der Daten!",
            style: TextStyle(color: Colors.red)));
  }

  String getSelectedFolder() {
    return _selectedFolderRef.getSelectedFolder();
  }

  Future showFile(String fileName) async {
    var folderName = getSelectedFolder();
    var fileBytes = await NetworkHelper.getFileBytes(
        _methodChannel, context, folderName, fileName);
    // open with pdf
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFView(pdfData: fileBytes),
        ));
  }

  Future shareFile(String fileName) async {
    var fileBytes = await NetworkHelper.getFileBytes(
        _methodChannel, context, getSelectedFolder(), fileName);
    // store file in temp folder
    var tempFolder = await getTemporaryDirectory();
    var tempFilePath = p.join(tempFolder.path, fileName);
    var tempFile = File(tempFilePath);
    await tempFile.writeAsBytes(fileBytes,
        mode: FileMode.writeOnly, flush: true);
    // if (await Permission.storage.request().isGranted) {
    await Share.shareFiles([tempFile.path],
        text: "Datei '$fileName' versenden über..");
  }

  Future deleteFile(String fileName) async {
    return {
      if (await NetworkHelper.deleteFile(
          _methodChannel, context, getSelectedFolder(), fileName))
        {
          SnackbarNotification(
              SnackbarType.success, "Datei $fileName wurde gelöscht")
            ..dispatch(context)
        }
      else
        {
          SnackbarNotification(
              SnackbarType.error, "Fehler beim löschend er Datei $fileName")
            ..dispatch(context)
        }
    };
  }

  List<String> getSelectedFiles() {
    return Provider.of<SelectedFiles>(context, listen: false)
        .getSelectedFiels();
  }

  Future<bool> mergeFiles() async {
    var result = await NetworkHelper.mergeFiles(_methodChannel, context,
        getSelectedFolder(), _fileNameTextController.text, getSelectedFiles());
    return result;
  }

  // load remote data

  Future<List<String>> loadFiles(String folderName) async {
    try {
      List<String> files =
          await NetworkHelper.listFiles(_methodChannel, context, folderName);
      files.sort((first, second) => first.compareTo(second));
      return files;
      // should be sorted by latest already
    } on Exception {
      SnackbarNotification(
          SnackbarType.error, "Fehler bei Abruf der Orderliste!");
    }
    return null;
  }

  /// Method for request to list folders from server
  Future<List<String>> loadFolders() async {
    try {
      List<String> folders =
          await NetworkHelper.listFolders(_methodChannel, context);
      return folders;
      // should be sorted by latest already
    } on Exception {
      SnackbarNotification(
          SnackbarType.error, "Fehler bei Abruf der Orderliste!");
    }
    return null;
  }
}
