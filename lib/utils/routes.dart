import 'package:flutte/screens/firstRun.dart';
import 'package:flutte/screens/home.dart';
import 'package:flutte/screens/splash.dart';
import 'package:flutter/material.dart';

class Routes {
  static const String Splash = '/splash';
  static const String FirstRun = '/firstRun';
  static const String Home = '/home';
}

final routesComponents = {
  Routes.Splash: (BuildContext context) => Splash(),
  Routes.FirstRun: (BuildContext context) => FirstRun(),
  Routes.Home: (BuildContext context) => Home(),
};
