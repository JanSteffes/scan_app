import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scan_app/models/datamodels/selected_files.dart';

class MergeView extends StatefulWidget {
  final Function mergeFunction;
  final TextEditingController _fileNameTextController;

  MergeView(this.mergeFunction, this._fileNameTextController, {Key key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _MergeViewState();
}

class _MergeViewState extends State<MergeView> {
  static const String _mainButtonText = "zusammenführen";
  static const String _noFileName = "Dateiname angeben!";

  @override
  Widget build(BuildContext context) {
    return Column(children: [buildFileNameOption(), buildMergeButton()]);
  }

  Widget buildFileNameOption() {
    return TextField(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: 'Dateiname',
        ),
        autocorrect: false,
        controller: widget._fileNameTextController,
        onChanged: (newValue) => setState(() => {}));
  }

  buildMergeButton() {
    return Consumer<SelectedFiles>(builder: (context, selectedFiles, child) {
      var mainButtonText = getMergeButtonText();
      return RaisedButton(
          onPressed: validateMergeInput() ? widget.mergeFunction.call : null,
          child: Text(mainButtonText));
    });
  }

  // validates inputs / selected files
  String getMergeButtonText() {
    var selectedFilesCount = getSelectedFilesCount();
    if (selectedFilesCount < 2) {
      return "Noch mindestens ${2 - selectedFilesCount} Datei(en) auswählen!";
    }
    if (widget._fileNameTextController.text == null ||
        widget._fileNameTextController.text.isEmpty) {
      return _noFileName;
    }
    return selectedFilesCount.toString() + " Dateien " + _mainButtonText;
  }

  bool validateMergeInput() {
    var selectedFiles = getSelectedFilesCount();
    return selectedFiles > 1 && widget._fileNameTextController.text.isNotEmpty;
  }

  int getSelectedFilesCount() {
    return Provider.of<SelectedFiles>(context).getCount();
  }
}
