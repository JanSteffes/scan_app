import 'package:flutter/widgets.dart';

class SelectedFiles extends ChangeNotifier {
  List<String> _selectedFiles;

  SelectedFiles() {
    _selectedFiles = List<String>();
  }

  int getCount() => _selectedFiles.length;

  List<String> getSelectedFiels() => _selectedFiles;

  void addFile(String fileName) {
    if (!_selectedFiles.contains(fileName)) {
      _selectedFiles.add(fileName);
      notifyListeners();
    }
  }

  void removeFile(String fileName) {
    if (_selectedFiles.contains(fileName)) {
      _selectedFiles.remove(fileName);
      notifyListeners();
    }
  }

  void clearFiles([bool skipNotify = false]) {
    _selectedFiles.clear();
    if (!skipNotify) {
      notifyListeners();
    }
  }
}

class SelectedFolder extends ChangeNotifier {
  String _selectedFolder;

  String getSelectedFolder() => _selectedFolder;

  void setFolder(String newValue, [bool skipNotify = false]) {
    if (newValue == _selectedFolder) {
      return;
    }
    _selectedFolder = newValue;
    if (!skipNotify) {
      notifyListeners();
    }
  }
}
