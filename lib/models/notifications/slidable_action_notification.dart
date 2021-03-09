import 'package:flutter/widgets.dart';
import 'package:scan_app/models/listmodels/slideable/slideable_action.dart';

abstract class SlideableActionNotification extends Notification {
  final SlideableAction slideableAction;

  const SlideableActionNotification(this.slideableAction);
}
