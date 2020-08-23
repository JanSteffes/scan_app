import 'NativeRequestNotification.dart';

class ScanNotification extends NativeRequestNotification {
  final String fileName;
  final int scanQuality;

  ScanNotification({this.fileName, this.scanQuality})
      : super({"FileName": fileName, "ScanQuality": scanQuality});
}
