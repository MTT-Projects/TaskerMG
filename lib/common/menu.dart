import 'package:dos/common/add_task_bar.dart';
import 'package:dos/common/pages/logs.dart';
import 'package:dos/common/pages/progress.dart';
import 'package:dos/common/theme.dart';
import 'package:dos/controllers/task_controller.dart';
import 'package:flutter/material.dart';
import 'package:bubble_bottom_bar/bubble_bottom_bar.dart';
import 'package:dos/common/home_page.dart';
import 'package:get/get.dart';
//import 'package:flutter_native_splash/flutter_native_splash.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = 0;
  }

  void changePage(int? index) {
    setState(() {
      currentIndex = index!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return tasksScreen(context) ;
  }

  Widget projectsScreen() {
    return Scaffold(
      body: Image.asset('assets/images/logo.png'),
    );
  }

  Scaffold tasksScreen(BuildContext context) {
    return Scaffold(
      body: <Widget>[
        HomePage(),
        const Logs(),
        ProgressPage(),
      ][currentIndex],
      bottomNavigationBar: BubbleBottomBar(
        backgroundColor: Colors.white,
        hasNotch: true,
        opacity: 0.5,
        currentIndex: currentIndex,
        onTap: changePage,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(25),
        ), //border radius doesn't work when the notch is enabled.
        elevation: 10,
        tilesPadding: const EdgeInsets.symmetric(
          vertical: 8.0,
        ),
        items: const <BubbleBottomBarItem>[
          BubbleBottomBarItem(
            backgroundColor: bluishClr,
            icon: Icon(
              Icons.pending_outlined,
              color: Colors.black,
            ),
            activeIcon: Icon(
              Icons.pending,
              color: Colors.white,
            ),
            title: Text(
              "Pendientes",
              style: TextStyle(color: Color(0xFFFFFFFF)),
            ),
          ),
          BubbleBottomBarItem(
            backgroundColor: bluishClr,
            icon: Icon(
              Icons.timelapse_outlined,
              color: Colors.black,
            ),
            activeIcon: Icon(
              Icons.timelapse,
              color: Colors.white,
            ),
            title: Text(
              "En progreso",
              style: TextStyle(color: Color(0xFFFFFFFF)),
            ),
          ),
          BubbleBottomBarItem(
            backgroundColor: bluishClr,
            icon: Icon(
              Icons.check_circle_outline_outlined,
              color: Colors.black,
            ),
            activeIcon: Icon(
              Icons.check_circle,
              color: Colors.white,
            ),
            title: Text(
              "Terminados",
              style: TextStyle(color: Color(0xFFFFFFFF)),
            ),
          ),
        ],
      ),
    );
  }
}