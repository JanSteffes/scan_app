import 'NativeRequestNotification.dart';

class MergeNotification extends NativeRequestNotification {
  final String fileName;
  final List<String> fileNames;

  MergeNotification({this.fileName, this.fileNames})
      : super({"FileName": fileName, "FileNames": fileNames});
}
