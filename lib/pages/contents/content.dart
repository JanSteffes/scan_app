import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///  BaseClass for content of action. Should handle most common stuff of network requests etc.
abstract class Content extends StatefulWidget {
  Content({Key key, this.methodChannel}) : super(key: key);

  final MethodChannel methodChannel;
}

/// State for contentclass
abstract class ContentState<T extends Content> extends State<T> {
  bool executingAsyncRequest = false;
  BuildContext currentContext;

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (BuildContext innerContext) {
      currentContext = innerContext;
      return executingAsyncRequest
          ? buildLoader()
          : Column(children: [
              Text(getTitle()),
              buildSpecificContent(context),
              buildActionButton()
            ]);
    });
  }

  Widget buildSpecificContent(BuildContext buildContext);
  bool validateInputs();
  dynamic getArguments();
  String getRequestMethod();
  String getTitle();
  Future successfullExcecutionCallBack(dynamic returnValue);
  String getMainButtonText();

  /// "main" purpose button on the bottom of the screen
  Widget buildActionButton() {
    return RaisedButton(
      onPressed: () => executeRequest(),
      child: Text(getMainButtonText()),
    );
  }

  /// try to execute the "main" purpose request, done by action button
  void executeRequest() async {
    if (validateInputs()) {
      var arguments = getArguments();
      var request = getRequestMethod();
      await sendNativeCommandRequest(request, arguments, true);
    }
  }

  /// Method for requests that trigger processing at the server
  Future<dynamic> sendNativeCommandRequest(String request, dynamic arguments,
      [bool callCallback = true]) async {
    setState(() {
      executingAsyncRequest = true;
    });
    try {
      var result = await widget.methodChannel.invokeMethod(request, arguments);
      if (result != null) {
        if (callCallback) {
          await successfullExcecutionCallBack(result);
        }
      } else {
        showErrorSnackbar();
      }
    } on PlatformException catch (e) {
      Scaffold.of(currentContext).showSnackBar(SnackBar(
          content: Text("Fehler beim Verarbeiten der Anfrage: " + e.message)));
    } finally {
      setState(() {
        executingAsyncRequest = false;
      });
    }
  }

  /// loader to show between asynchron actions
  Widget buildLoader() {
    return Column(children: [
      CircularProgressIndicator(),
      Text("Die Anfrage wird verarbeitet...")
    ]);
  }

  /// show snackbar with success theme
  showSuccessSnackbar() {
    Scaffold.of(currentContext).showSnackBar(SnackBar(
        content: Row(children: [
      Icon(Icons.done, size: 24.0, color: Colors.red),
      getSpacer(),
      Text("Verarbeitung erfolgreich abgeschlossen")
    ])));
  }

  showInfoSnackbar(String text) {
    Scaffold.of(currentContext).showSnackBar(SnackBar(
        content: Row(children: [
      Icon(Icons.info, color: Colors.blue, size: 24.0),
      getSpacer(),
      Text(text, maxLines: 2)
    ])));
  }

  /// show snackbar with error theme
  showErrorSnackbar([String text]) {
    Scaffold.of(currentContext).showSnackBar(SnackBar(
        content: Row(children: [
      Icon(Icons.error, color: Colors.red, size: 24.0),
      getSpacer(),
      Text(text ?? "Fehler bei Verarbeitung der Anfrage", maxLines: 2)
    ])));
  }

  /// Small horizontal spacer
  Widget getSpacer() {
    return Container(width: 10, height: 0);
  }
}
