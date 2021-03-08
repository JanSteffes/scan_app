import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:install_plugin/install_plugin.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:scan_app/helper/network_helper.dart';
import 'package:scan_app/models/datamodels/context_model.dart';
import 'package:scan_app/models/enums/snackbar_type.dart';
import 'package:scan_app/models/notifications/snackbar_notification.dart';

import 'contents/manage_files_content.dart';
import 'contents/scan_content.dart';
import 'package:scan_app/models/enums/request_type.dart';
import 'package:path/path.dart' as p;

class ScanHomePage extends StatefulWidget {
  ScanHomePage({Key key}) : super(key: key);

  @override
  _ScanHomePageState createState() => _ScanHomePageState();
}

class _ScanHomePageState extends State<ScanHomePage> {
  static const _methodChannel =
      const MethodChannel('flutter.native/scanHelper');
  BuildContext scaffoldContext;
  ContextModel contextModel;
  static const String _title = 'Scan App';

  @override
  void dispose() {
    // clear temp files
    getTemporaryDirectory().then((value) => value.delete(recursive: true));
    super.dispose();
  }

  @override
  Widget build(BuildContext buildContext) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              title: Text(_title),
              actions: buildAppbarActions(),
              bottom: TabBar(
                physics: NeverScrollableScrollPhysics(),
                tabs: [
                  Tab(
                      icon: Icon(Icons.scanner, color: Colors.black),
                      child: tabText('Scannen')),
                  Tab(
                      icon: Icon(Icons.storage, color: Colors.black),
                      child: tabText('Dateien verwalten'))
                ],
              ),
            ),
            body: Consumer<ContextModel>(builder: (context, model, child) {
              return Builder(builder: (BuildContext scaffoldBuilderContext) {
                scaffoldContext = scaffoldBuilderContext;
                return NotificationListener<SnackbarNotification>(
                    child: buildTabContents(),
                    onNotification: (notification) => showSnackbar(
                        notification.snackbarType, notification.message));
              });
            })));
  }

  Widget buildTabContents() {
    return TabBarView(physics: NeverScrollableScrollPhysics(), children: [
      tabWrapper(ScanContent()),
      tabWrapper(ManageFilesContent()),
    ]);
  }

  Widget tabText(String text) {
    return RichText(
        text: TextSpan(
      style: TextStyle(color: Colors.black),
      text: text,
    ));
  }

  Widget tabWrapper(Widget content) {
    return Builder(builder: (BuildContext innerContext) {
      return Container(
        color: Colors.grey[200],
        child: Padding(
            padding: new EdgeInsets.all(10),
            child: Center(child: SingleChildScrollView(child: content))),
      );
    });
  }

  List<Widget> buildAppbarActions() {
    var popUpMenu = PopupMenuButton(
        onSelected: handleClick,
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem<String>(
              child: Text("Wechsel Server"),
              value: "switchEndpoint",
            ),
            PopupMenuItem<String>(
              child: Text("Wechsel Umgebung"),
              value: "switchEnvironment",
            ),
            PopupMenuItem<String>(
              child: Text("Updates"),
              value: "update",
            )
          ];
        });
    return [popUpMenu];
  }

  void handleClick(String value) {
    log("handle click for '" + value + "'");
    switch (value) {
      case "switchEndpoint":
        switchEndpoint();
        break;
      case "switchEnvironment":
        switchEnvironment();
        break;
      case "update":
        updateCheck();
        break;
    }
  }

  switchEnvironment() async {
    var endPoint = await _methodChannel.invokeMethod(
        RequestType.switchEnvironmentRequest.toString().split('.').last);
    showSnackbar(SnackbarType.info, "Umgebung gewechselt auf $endPoint");
  }

  switchEndpoint() async {
    var endPoint = await _methodChannel.invokeMethod(
        RequestType.switchEndpointRequest.toString().split('.').last);
    showSnackbar(SnackbarType.info, "Neuer Endpoint: $endPoint");
  }

  updateCheck() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String appName = packageInfo.appName;
    String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;
    log("appName: " + appName);
    log("packageName: " + packageName);
    log("version: " + version);
    log("buildNumber: " + buildNumber);
    bool updateNeeded =
        await NetworkHelper.checkUpdate(_methodChannel, context, version);
    if (!updateNeeded) {
      showSnackbar(SnackbarType.info, "Kein Update verfügbar");
    } else {
      showUpdateDialog();
    }
  }

  showUpdateDialog() {
    // set up the buttons
    showDialog(
      context: context,
      builder: (BuildContext alertContext) {
        return AlertDialog(
            title: Text("Update verfügbar"),
            content:
                Text("Soll das Update jetzt geladen und installiert werden?"),
            actions: [
              FlatButton(child: Text("Ja"), onPressed: performUpdate),
              FlatButton(
                child: Text("Nein"),
                onPressed: () => Navigator.pop(alertContext),
              ),
            ]);
      },
    );
  }

  performUpdate() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    String packageName = packageInfo.packageName;
    List<int> fileBytes =
        await NetworkHelper.loadUpdate(_methodChannel, context, version);
    // write file to tempdir
    if (fileBytes == null || fileBytes.isEmpty) {
      showSnackbar(SnackbarType.error, "Update wurde nicht korrekt geladen!");
    } else {
      final tempDirectory = await getTemporaryDirectory();
      var directoryPath = p.join(tempDirectory.path, "scan_app");
      var tempFile = File('$directoryPath/latest.apk');
      await Directory(directoryPath).create();
      tempFile.writeAsBytesSync(fileBytes,
          mode: FileMode.writeOnly, flush: true);
      await InstallPlugin.installApk(tempFile.path, packageName);
    }
  }

  showSnackbar(SnackbarType type, String message) {
    Icon icon;
    var text = message;
    switch (type) {
      case SnackbarType.info:
        icon = Icon(Icons.info, color: Colors.blue, size: 24.0);
        break;
      case SnackbarType.warning:
        throw UnimplementedError("SnackbarType warning not implemented!");
        break;
      case SnackbarType.error:
        icon = Icon(Icons.error, color: Colors.red, size: 24.0);
        text = text ?? "Fehler bei Verarbeitung der Anfrage";
        break;
      case SnackbarType.success:
        icon = Icon(Icons.done, size: 24.0, color: Colors.green);
        text = text ?? "Verarbeitung erfolgreich abgeschlossen";
        break;
    }
    Scaffold.of(scaffoldContext).showSnackBar(SnackBar(
        content: Row(
            children: [icon, getHorizontalSpacer(), Text(text, maxLines: 2)])));
  }

  /// Small horizontal spacer
  Widget getHorizontalSpacer() {
    return Container(width: 10, height: 0);
  }
}
