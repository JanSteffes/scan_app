import 'package:scan_app/models/listmodels/slideable/slideable_action.dart';
import 'package:scan_app/models/notifications/slidable_action_notification.dart';

class SlideableSelectActionNotification extends SlideableActionNotification {
  final bool isSelectAction;
  final String fileName;

  SlideableSelectActionNotification(
      SlideableAction slideableAction, this.isSelectAction, this.fileName)
      : super(slideableAction);
}
