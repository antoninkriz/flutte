import 'package:flutte/screens/splash.dart';
import 'package:flutte/utils/routes.dart';
import 'package:flutte/utils/texts.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) => Locals.of(context).loc('title'),
      localizationsDelegates: [const LocalsDelegate()],
      supportedLocales: [
        const Locale('en', ''),
        const Locale('cs', ''),
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.lightBlue.shade800,
        accentColor: Colors.lightBlue.shade600,
      ),
      routes: routesComponents,
      home: Splash(),
    );
  }
}
