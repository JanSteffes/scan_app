import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:libdsm/libdsm.dart';

class UpdateScreen extends StatefulWidget {
  UpdateScreen({Key key}) : super(key: key);

  @override
  _UpdateScreenState createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  Dsm dsm = Dsm();
  BuildContext scaffoldContext;
  int sessionId;

  setSessionId(int newSessionId) {
    setState(() => {sessionId = newSessionId});
  }

  @override
  void initState() {
    super.initState();
    updateCheck();
  }

  @override
  Widget build(BuildContext context) {
    // loading circle
    // text "checking for update..."
    // if update -> do stuff
    // if all up to date, just go to main page
    return Scaffold(body:
        SizedBox.expand(child: Builder(builder: (BuildContext innerContext) {
      scaffoldContext = innerContext;
      return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Text('Updating...'),
            // SizedBox(height: 20),
            // CircularProgressIndicator(),
            // SizedBox(height: 20),
            RaisedButton(
              onPressed: _create,
              child: Text('create'),
            ),
            RaisedButton(
              onPressed: _release,
              child: Text('release'),
            ),
            RaisedButton(
              onPressed: _startDiscovery,
              child: Text('startDiscovery'),
            ),
            RaisedButton(
              onPressed: _stopDiscovery,
              child: Text('stopDiscovery'),
            ),
            RaisedButton(
              onPressed: _resolve,
              child: Text('resolve'),
            ),
            RaisedButton(
              onPressed: _inverse,
              child: Text('inverse'),
            ),
            RaisedButton(
              onPressed: _login,
              child: Text('login'),
            ),
            RaisedButton(
              onPressed: _logout,
              child: Text('logout'),
            ),
            RaisedButton(
              onPressed: _getShareList,
              child: Text('getShareList'),
            ),
            RaisedButton(
              onPressed: _treeConnect,
              child: Text('treeConnect'),
            ),
            RaisedButton(
              onPressed: _treeDisconnect,
              child: Text('treeDisconnect'),
            ),
            RaisedButton(
              onPressed: _find,
              child: Text('find'),
            ),
            RaisedButton(
              onPressed: _fileStatus,
              child: Text('fileStatus'),
            ),
            RaisedButton(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/mainScreen'),
              child: Text("Weiter zur Startseite"),
            )
          ]);
    })));
  }

  updateCheck() {}

  moveToMainPage() {
    Navigator.of(context).pushReplacementNamed('/mainScreen');
  }

  void _create() async {
    await dsm.init();
  }

  void _release() async {
    await dsm.release();
  }

  void _startDiscovery() async {
    dsm.onDiscoveryChanged.listen(_discoveryListener);
    await dsm.startDiscovery();
  }

  void _discoveryListener(String json) async {
    debugPrint('Discovery : $json');
  }

  void _stopDiscovery() async {
    dsm.onDiscoveryChanged.listen(null);
    await dsm.stopDiscovery();
  }

  void _resolve() async {
    String name = 'raspberrypi';
    var result = await dsm.resolve(name);
    showSnack(result);
  }

  void _inverse() async {
    String address = '192.168.0.237';
    var result = await dsm.inverse(address);
    showSnack(result);
  }

  void _login() async {
    var sessionId = await dsm.login("raspberrypi", "pi-share", "2A661D2828");
    showSnack('New sessionId: ' + sessionId.toString());
    setSessionId(sessionId);
  }

  void _logout() async {
    await dsm.logout();
  }

  void _getShareList() async {
    await dsm.getShareList();
  }

  int tid = 0;

  void _treeConnect() async {
    tid = await dsm.treeConnect("App-Share");
    showSnack(tid.toString());
  }

  void _treeDisconnect() async {
    int result = await dsm.treeDisconnect(tid);
    tid = 0;
  }

  void _find() async {
    String result = await dsm.find(tid, "\\*");
    result = await dsm.find(tid, "\\raspberrypi\\App-Share\\ScanClient\\*");
    showSnack(result);
  }

  void _fileStatus() async {
    String result = await dsm.fileStatus(
        sessionId, "\\raspberrypi\\App-Share\\ScanClient\\Test.txt");
    showSnack(result);
  }

  void showSnack(String message) {
    Scaffold.of(scaffoldContext).showSnackBar(SnackBar(content: Text(message)));
  }
}
