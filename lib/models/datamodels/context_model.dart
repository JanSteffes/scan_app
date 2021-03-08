import 'dart:developer';

import 'package:flutter/widgets.dart';

class ContextModel extends ChangeNotifier {
  String _currentFolder;

  void setFolder(String folder, [bool skipNotify = false]) {
    log("setting folder to '" + folder + "'");
    _currentFolder = folder;
    if (!skipNotify) {
      notifyListeners();
    }
  }

  String getFolder() {
    return _currentFolder;
  }
}
