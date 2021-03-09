import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scan_app/models/datamodels/selected_files.dart';
import 'pages/init_screen.dart';
import 'pages/scan_homepage.dart';

void main() {
  runApp(ChangeNotifierProvider(
      create: (context) => SelectedFiles(),
      child: ChangeNotifierProvider(
          create: (context) => SelectedFolder(), child: MyApp())));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Scan App',
        theme: ThemeData(
            // This is the theme of your application.
            //
            // Try running your application with "flutter run". You'll see the
            // application has a blue toolbar. Then, without quitting the app, try
            // changing the primarySwatch below to Colors.green and then invoke
            // "hot reload" (press "r" in the console where you ran "flutter run",
            // or simply save your changes to "hot reload" in a Flutter IDE).
            // Notice that the counter didn't reset back to zero; the application
            // is not restarted.
            primarySwatch: Colors.blue,
            splashColor: Colors.blue[900],
            // This makes the visual density adapt to the platform that you run
            // the app on. For desktop platforms, the controls will be smaller and
            // closer together (more dense) than on mobile platforms.
            visualDensity: VisualDensity.adaptivePlatformDensity,
            buttonColor: Colors.white,
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: const OutlineInputBorder(),
              labelStyle: TextStyle(backgroundColor: Colors.white),
            ),
            canvasColor: Colors.white,
            textTheme:
                TextTheme(bodyText1: TextStyle(backgroundColor: Colors.white))),
        home: ScanHomePage(),
        routes: <String, WidgetBuilder>{
          '/mainScreen': (BuildContext context) => ScanHomePage(),
          '/init': (BuildContext context) => InitScreen(),
          //'/update': (BuildContext context) => UpdateScreen()
        });
  }
}
