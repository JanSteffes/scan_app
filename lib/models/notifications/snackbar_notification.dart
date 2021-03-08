import 'package:flutter/cupertino.dart';
import 'package:scan_app/models/enums/snackbar_type.dart';

class SnackbarNotification extends Notification {
  final SnackbarType snackbarType;

  final String message;

  const SnackbarNotification(this.snackbarType, [this.message]);
}
