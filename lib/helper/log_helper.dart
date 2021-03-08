import 'dart:developer';

class LogHelper {
  static logMessage(String message) {
    log(message, time: DateTime.now());
  }
}
