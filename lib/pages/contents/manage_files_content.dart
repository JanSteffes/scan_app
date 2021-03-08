import 'dart:io';

import 'package:async_builder/async_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:scan_app/helper/network_helper.dart';
import 'package:scan_app/models/datamodels/context_model.dart';
import 'package:scan_app/models/enums/snackbar_type.dart';
import 'package:scan_app/models/listmodels/file_item.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:scan_app/models/listmodels/slideable/slideable_action.dart';
import 'package:scan_app/models/notifications/snackbar_notification.dart';
import 'package:scan_app/widgets/file_list_controller.dart';
import 'package:scan_app/widgets/folder_file_view.dart';
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
  TextEditingController _fileNameTextController = TextEditingController();
  static const String _mainButtonText = "zusammenführen";
  static const String _mainButtonNoFileText = "Mindestens 2 Dateien auswählen!";
  static const String _noFileName = "Dateiname angeben!";

  FileListController _fileListController = FileListController();
  Future _folderLoadFuture;

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback(
    //     (_) => refreshFolders().then((value) => refreshFileList()));
    _folderLoadFuture = loadFolders();
  }

  @override
  Widget build(BuildContext buildContext) {
    return Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      buildFolderSelection(),
      SizedBox(height: 10),
      buildMergeView()
    ]);
  }

  Widget buildFolderSelection() {
    return AsyncBuilder<List<String>>(
        future: _folderLoadFuture,
        waiting: (context) => CircularProgressIndicator(),
        builder: (context, List<String> data) {
          return FolderFileView(_fileListController, data, loadFiles, {
            SlideableAction.see: showFile,
            SlideableAction.delete: deleteFile,
            SlideableAction.share: shareFile
          });
        },
        error: (context, error, stacktrace) => Text(
            "Fehler bei Anfrage der Daten!",
            style: TextStyle(color: Colors.red)));
  }

  Widget buildMergeView() {
    return Column(children: [buildFileNameOption(), buildMergeButton()]);
  }

  Widget buildFileNameOption() {
    return TextField(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: 'Dateiname',
        ),
        autocorrect: false,
        controller: _fileNameTextController);
  }

  buildMergeButton() {
    var mainButtonText = getMergeButtonText();
    return RaisedButton(
        onPressed: () => validateMergeInput()
            ? () => NetworkHelper.mergeFiles(
                _methodChannel,
                context,
                _fileListController.folderName,
                _fileNameTextController.text,
                getSelectedFiles().map((v) => v.fileName).toList())
            : null,
        child: Text(mainButtonText));
  }

  Widget buildLegendItem(IconData icon, String text) {
    return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [Icon(icon), Text(text)]);
  }

  bool validateMergeInput() {
    var selectedFiles = getSelectedFiles();
    return selectedFiles != null &&
        selectedFiles.length > 1 &&
        _fileNameTextController.text.isNotEmpty;
  }

  List<FileItem> getSelectedFiles() {
    return _fileListController.selectedFiles;
  }

  Future showFile(String folderName, String fileName) async {
    var fileBytes = await NetworkHelper.getFileBytes(
        _methodChannel, context, folderName, fileName);
    // open with pdf
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFView(pdfData: fileBytes),
        ));
  }

  Future shareFile(String folderName, String fileName) async {
    var fileBytes = await NetworkHelper.getFileBytes(
        _methodChannel, context, folderName, fileName);
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

  // validates inputs / selected files
  String getMergeButtonText() {
    if (_fileNameTextController.text == null ||
        _fileNameTextController.text.isEmpty) {
      return _noFileName;
    }
    var selectedFilesCount = getSelectedFiles()?.length ?? 0;
    return selectedFilesCount < 2
        ? _mainButtonNoFileText
        : selectedFilesCount.toString() + " Dateien " + _mainButtonText;
  }

  Future deleteFile(String folderName, String fileName) async {
    return {
      if (await NetworkHelper.deleteFile(
          _methodChannel, context, folderName, fileName))
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

  /// Get current selected folder of contextModel
  String getCurrentWorkingFolder() =>
      Provider.of<ContextModel>(context, listen: false).getFolder();

  // load remote data

  Future<List<String>> loadFiles(String folderName) async {
    try {
      List<String> files =
          await NetworkHelper.listFiles(_methodChannel, context, folderName);
      files.sort((first, second) => first.compareTo(second));
      return files;
      // should be sorted by latest already
    } on Exception catch (e) {
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
    } on Exception catch (e) {
      SnackbarNotification(
          SnackbarType.error, "Fehler bei Abruf der Orderliste!");
    }
    return null;
  }
}
