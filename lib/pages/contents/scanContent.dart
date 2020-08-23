import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuple/tuple.dart';

import 'content.dart';

class ScanContent extends Content {
  ScanContent({Key key, MethodChannel methodChannel})
      : super(key: key, methodChannel: methodChannel);

  @override
  _ScanContentState createState() => _ScanContentState();
}

class _ScanContentState extends ContentState<ScanContent> {
  TextEditingController _fileNameTextController = TextEditingController();
  int _scanQuality = 0;
  static const String _title = "Scannen";
  static const String _requestMethod = "scanRequest";

  Set<Tuple2<int, String>> _scanOptions = {
    Tuple2<int, String>(0, "Schnell"),
    Tuple2<int, String>(1, "Normal"),
    Tuple2<int, String>(2, "Besser"),
    Tuple2<int, String>(3, "Am Besten")
  };
  Widget buildOptionsTitle() {
    return Align(alignment: Alignment.topLeft, child: Text("Scanqualität:"));
  }

  // Build radio buttons
  Widget buildRadioButtons() {
    return Container(
        color: Colors.transparent,
        child: Column(
            children: _scanOptions
                .map((value) => buildRadioButton(value.item1, value.item2))
                .toList(),
            mainAxisAlignment: MainAxisAlignment.center));
  }

  Future successfullExcecutionCallBack() {
    showSuccessSnackbar();
    return null;
  }

  String getMainButtonText() {
    return _title;
  }

  Widget buildFileNameOption() {
    return TextField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: 'Dateiname',
      ),
      autocorrect: false,
      controller: _fileNameTextController,
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

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _fileNameTextController.dispose();
    super.dispose();
  }

  @override
  Widget buildSpecificContent(BuildContext buildContext) {
    return Column(children: [
      buildOptionsTitle(),
      buildRadioButtons(),
      buildFileNameOption()
    ]);
  }

  @override
  getArguments() {
    return {
      "ScanQuality": _scanQuality,
      "FileName": _fileNameTextController.text
    };
  }

  @override
  String getRequestMethod() {
    return _requestMethod;
  }

  @override
  String getTitle() {
    return _title;
  }

  @override
  bool validateInputs() {
    return _fileNameTextController.text.isNotEmpty;
  }
}
