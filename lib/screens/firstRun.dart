import 'package:flutte/data/animated_icons.dart';
import 'package:flutte/utils/texts.dart';
import 'package:flutter/material.dart';
import 'package:page_view_indicator/page_view_indicator.dart';

class FirstRun extends StatefulWidget {
  @override
  _FirstRunState createState() => _FirstRunState();
}

class _FirstRunState extends State<FirstRun> with SingleTickerProviderStateMixin {
  final _pagesCount = 4;
  final _pageIndex = ValueNotifier<int>(0);
  final _pageController = PageController();
  AnimationController _iconsController;

  String Function(String) _loc;

  @override
  void initState() {
    super.initState();

    _iconsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      value: 0,
      vsync: this,
    );

    _pageIndex.addListener(() {
      if (_pageIndex.value == _pagesCount - 1) {
        _iconsController.fling(velocity: 2.0);
      } else {
        _iconsController.fling(velocity: -2.0);
      }
    });
  }

  @override
  void dispose() {
    _pageIndex.dispose();
    _pageController.dispose();
    _iconsController.dispose();
    super.dispose();
  }

  void switchToNextPage() {
    if (_pageIndex.value < 3) {
      _pageController.animateToPage(_pageIndex.value + 1, duration: Duration(milliseconds: 400), curve: Curves.ease);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _onWillPop() {
    if (_pageIndex.value > 0) {
      _pageController.animateToPage(_pageIndex.value - 1, duration: Duration(milliseconds: 400), curve: Curves.ease);

      return Future<bool>(() => false);
    } else {
      return Future<bool>(() => true);
    }
  }

  @override
  Widget build(BuildContext context) {
    _loc = Locals.of(context).loc;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: switchToNextPage,
          backgroundColor: Colors.blueAccent.shade700,
          child: CustomAnimatedIcon(
            icon: CustomAnimatedIcons.arrow_close,
            progress: _iconsController.view,
          ),
        ),
        body: Stack(
          alignment: FractionalOffset.bottomCenter,
          children: [
            PageView(
              onPageChanged: (i) => _pageIndex.value = i,
              controller: _pageController,
              children: [
                Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Welecome!',
                          style: TextStyle(fontSize: 32, color: Colors.white),
                        ),
                        Text(
                          'Simple app to track your expenses',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.shade800,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Welecome!',
                          style: TextStyle(fontSize: 32, color: Colors.white),
                        ),
                        Text(
                          'Simple app to track your expenses',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.lightGreen.shade700,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Welecome!',
                          style: TextStyle(fontSize: 32, color: Colors.white),
                        ),
                        Text(
                          'Simple app to track your expenses',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Welecome!',
                          style: TextStyle(fontSize: 32, color: Colors.white),
                        ),
                        Text(
                          'Simple app to track your expenses',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            PageViewIndicator(
              pageIndexNotifier: _pageIndex,
              length: _pagesCount,
              normalBuilder: (animationController, index) {
                return Circle(size: 8, color: Colors.white54);
              },
              highlightedBuilder: (animationController, index) {
                return ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animationController,
                    curve: Curves.ease,
                  ),
                  child: Circle(
                    size: 8,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
