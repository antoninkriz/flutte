import 'dart:async';

import 'package:flutte/utils/globals.dart';
import 'package:flutte/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  Future checkFirstSeen() async {
    // Shared prefs
    var prefs = await SharedPreferences.getInstance();
    var _seen = (prefs.getBool('firstRunComplete') ?? false);

    if (Globals.isDebug) {
      Navigator.of(context).pushReplacementNamed(Routes.Home);
      Navigator.of(context).pushNamed(Routes.FirstRun);
      return;
    }

    Navigator.of(context).pushReplacementNamed(Routes.Home);

    if (!_seen) {
      prefs.setBool('firstRunComplete', true);
      Navigator.of(context).pushNamed(Routes.FirstRun);
    }
  }

  @override
  void initState() {
    super.initState();
    Timer(Duration(milliseconds: 1000), () {
      checkFirstSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 128,
          height: 128,
          child: Text('Splash'), //Image(image: AssetImage('assets/icon.png')),
        ),
      ),
    );
  }
}
