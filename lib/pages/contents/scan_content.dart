import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:scan_app/helper/network_helper.dart';
import 'package:scan_app/models/enums/snackbar_type.dart';
import 'package:scan_app/models/notifications/snackbar_notification.dart';
import 'package:tuple/tuple.dart';

class ScanContent extends StatefulWidget {
  ScanContent({Key key}) : super(key: key);

  @override
  _ScanContentState createState() => _ScanContentState();
}

class _ScanContentState extends State<ScanContent> {
  static const _methodChannel =
      const MethodChannel('flutter.native/scanHelper');
  TextEditingController _fileNameTextController = TextEditingController();
  int _scanQuality = 0;
  static const String _noFileNameText = "Dateiname angeben!";

  Set<Tuple2<int, String>> _scanOptions = {
    Tuple2<int, String>(0, "Schnell"),
    Tuple2<int, String>(1, "Normal"),
    Tuple2<int, String>(2, "Besser"),
    Tuple2<int, String>(3, "Am Besten")
  };

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _fileNameTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext buildContext) {
    return Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Row(children: [buildScanFolderView(), Expanded(child: Container())]),
      SizedBox(height: 10),
      buildScanQualityMenu(),
      buildFileNameOption(),
      buildScanButton()
    ]);
  }

  Widget buildScanFolderView() {
    return Text("Aktueller Zielordner: ${getCurrentDateFolderName()}");
  }

  String getCurrentDateFolderName() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Widget buildScanQualityMenu() {
    return Column(children: [
      Align(alignment: Alignment.topLeft, child: Text("Scanqualität:")),
      Container(
          color: Colors.transparent,
          child: Column(
              children: _scanOptions
                  .map((value) => buildRadioButton(value.item1, value.item2))
                  .toList(),
              mainAxisAlignment: MainAxisAlignment.center))
    ]);
  }

  Widget buildFileNameOption() {
    return TextField(
      decoration: InputDecoration(hintText: 'Dateiname'),
      autocorrect: false,
      controller: _fileNameTextController,
      onChanged: (string) => setState(() => {}),
    );
  }

  // build a single radio button
  Widget buildRadioButton(int value, String label) {
    var button = new RadioListTile(
        title: Text(label),
        value: value,
        groupValue: _scanQuality,
        onChanged: (val) => setQuality(val));
    return button;
  }

  void setQuality(int scanQuality) {
    setState(() {
      _scanQuality = scanQuality;
    });
  }

  // build button to scan
  Widget buildScanButton() {
    var validInputs = validateInputs();
    return RaisedButton(
        onPressed: validInputs ? () => scanFile() : null,
        child: Text(validInputs ? "Scannen" : _noFileNameText));
  }

  // scan file
  Future<dynamic> scanFile() async {
    if (validateInputs()) {
      bool result = await NetworkHelper.scan(
          _methodChannel,
          context,
          _scanQuality,
          // always scan to current dates folder
          getCurrentDateFolderName(),
          _fileNameTextController.text);
      var snackbarType = result ? SnackbarType.success : SnackbarType.error;
      SnackbarNotification(snackbarType)..dispatch(context);
    }
  }

  // validateInput of filename
  bool validateInputs() {
    var valid = _fileNameTextController.text.isNotEmpty;
    return valid;
  }
}
