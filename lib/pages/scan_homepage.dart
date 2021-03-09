import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:install_plugin/install_plugin.dart';
import 'package:intl/intl.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scan_app/helper/network_helper.dart';
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
  static const String _title = 'Scan App';

  BuildContext _performUpdateDialogContext;

  @override
  void dispose() {
    // clear temp files
    getTemporaryDirectory().then((value) => value.delete(recursive: true));
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
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
            body: Builder(builder: (BuildContext scaffoldBuilderContext) {
              scaffoldContext = scaffoldBuilderContext;
              return NotificationListener<SnackbarNotification>(
                  child: buildTabContents(),
                  onNotification: (notification) => showSnackbar(
                      notification.snackbarType, notification.message));
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
            ),
            PopupMenuItem<String>(
              child: Text("App-Info"),
              value: "appInfo",
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
      case "appInfo":
        showAppInfo();
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
      showUpdateDialog(packageName);
    }
  }

  showUpdateDialog(String packageName) {
    // set up the buttons
    showDialog(
      context: context,
      builder: (BuildContext alertContext) {
        return AlertDialog(
            title: Text("Update verfügbar"),
            content:
                Text("Soll das Update jetzt geladen und installiert werden?"),
            actions: [
              TextButton(
                  child: Text("Ja"),
                  onPressed: () =>
                      showPerformUpdateDialog(alertContext, packageName)),
              TextButton(
                child: Text("Nein"),
                onPressed: () => Navigator.pop(alertContext),
              ),
            ]);
      },
    );
  }

  showPerformUpdateDialog(
      BuildContext oldAlertContext, String packageName) async {
    Navigator.pop(oldAlertContext);
    var permissionState = await Permission.storage.request();
    if (permissionState.isGranted) {
      showDialog(
          context: context,
          builder: (BuildContext alertContext) {
            _performUpdateDialogContext = alertContext;
            return AlertDialog(
                title: Text("Update wird geladen.."),
                content: CircularProgressIndicator());
          });
      loadUpdateData();
    } else {
      showSnackbar(SnackbarType.error, "Update konnte nicht geladen werden!");
    }
  }

  Future loadUpdateData() async {
    var data = await loadApkData();
    // write update file to storage
    var baseDirPath = await getExternalStorageDirectory();
    var directoryPath =
        Directory(p.join(baseDirPath.path, "com.example.scan_app"));
    // var directoryPath = p.join(tempDirectory.path, "scan_app");
    log("Path to directory: '$directoryPath'");
    var tempFile = File(p.join(directoryPath.path, "latest.apk"));
    var tempFilePath = tempFile.path;
    log("FilePath: $tempFilePath");
    try {
      if (await tempFile.exists()) {
        log("File exists, will delete...");
        await tempFile.delete();
        log("File deleted.");
      }
      log("Begin writing to storage...");
      log("Creating directories $directoryPath");
      var createdDir = await directoryPath.create(recursive: true);
      if (!await createdDir.exists()) {
        showSnackbar(SnackbarType.error, "Update fehlgeschlagen");
        Navigator.pop(_performUpdateDialogContext);
        return;
      }
      log("Create/Write to file $tempFilePath");
      tempFile = await tempFile.writeAsBytes(data,
          mode: FileMode.writeOnly, flush: true);
    } on Exception catch (e) {
      log("Exception: $e");
    }
    if (!await tempFile.exists()) {
      showSnackbar(SnackbarType.error, "Update fehlgeschlagen");
      Navigator.pop(_performUpdateDialogContext);
      return;
    }
    var packageInfo = await PackageInfo.fromPlatform();
    // remove previous alert
    Navigator.pop(_performUpdateDialogContext);
    showDialog(
        context: context,
        builder: (BuildContext alertContext) {
          return AlertDialog(
              title: Text("Update fertig geladen"),
              content: Text("Soll das Update nun installiert werden?"),
              actions: [
                TextButton(
                    child: Text("Ja"),
                    onPressed: () =>
                        installUpdate(packageInfo, tempFile, alertContext)),
                TextButton(
                    child: Text("Nein"),
                    onPressed: () => Navigator.pop(alertContext))
              ]);
        });
  }

  showAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    int installDate = await _methodChannel.invokeMethod(
        RequestType.installDateInfoRequest.toString().split('.').last);
    var informationMapping = {
      "App-Name": packageInfo.appName,
      "Paket-Name": packageInfo.packageName,
      "Version": packageInfo.version,
      "Letzte Aktualisierung":
          "${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(installDate))} Uhr"
      // "Build-Nummer": packageInfo.buildNumber
    };
    List<Widget> dialogInfoChildren = informationMapping.entries
        .map((e) => Column(children: [
              Text(
                "${e.key}:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("${e.value}"),
            ], crossAxisAlignment: CrossAxisAlignment.start))
        .cast<Widget>()
        .toList();
    dialogInfoChildren.add(Container(color: Colors.green));
    showDialog(
        context: context,
        builder: (BuildContext alertContext) {
          return AlertDialog(
              title: Text("App-Informationen"),
              content: Column(
                children: dialogInfoChildren,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
              ),
              actions: [
                TextButton(
                  child: Text("Ok"),
                  onPressed: () => Navigator.pop(alertContext),
                ),
              ]);
        });
  }

  Future<List<int>> loadApkData() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    List<int> fileBytes =
        await NetworkHelper.loadUpdate(_methodChannel, context, version);
    return fileBytes;
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

  installUpdate(
      PackageInfo packageInfo, File tempFile, BuildContext alertContext) async {
    try {
      await InstallPlugin.installApk(tempFile.path, packageInfo.packageName);
      Navigator.pop(alertContext);
    } on Exception catch (e) {
      log("Exception while installing: $e");
    }
  }
}
