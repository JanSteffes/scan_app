import 'package:flutter/widgets.dart';
import 'package:scan_app/models/listmodels/slideable/slideable_action.dart';

class SlideableActionNotification extends Notification {
  final SlideableAction _slideableAction;

  const SlideableActionNotification(this._slideableAction);
}
