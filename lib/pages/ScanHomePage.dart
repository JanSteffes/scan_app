import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'contents/manageContent.dart';
import 'contents/scanContent.dart';

class ScanHomePage extends StatefulWidget {
  ScanHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ScanHomePageState createState() => _ScanHomePageState();
}

class _ScanHomePageState extends State<ScanHomePage> {
  static const methodChannel = const MethodChannel('flutter.native/scanHelper');

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              bottom: TabBar(
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
            body: TabBarView(children: [
              tabWrapper(ScanContent(methodChannel: methodChannel)),
              tabWrapper(ManageFilesContent(methodChannel: methodChannel)),
            ])));
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
      return Center(
          child: Padding(
              padding: new EdgeInsets.all(10),
              child: SingleChildScrollView(child: content)));
    });
  }
}
