import 'package:scan_app/models/listmodels/file_item.dart';

class FileListController {
  List<FileItem> selectedFiles;
  String folderName;

  void setFiles(List<FileItem> newSelectedFiles) {
    newSelectedFiles.sort((first, second) => first.compareTo(second));
    selectedFiles = newSelectedFiles;
  }

  void setFolder(String newFolderName) {
    folderName = newFolderName;
  }
}
