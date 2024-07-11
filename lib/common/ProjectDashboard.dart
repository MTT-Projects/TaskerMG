// ignore_for_file: prefer_const_constructors

import 'package:taskermg/common/add_task_bar.dart';
import 'package:taskermg/common/pages/logs.dart';
import 'package:taskermg/common/pages/progress.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/controllers/task_controller.dart';
import 'package:flutter/material.dart';
import 'package:bubble_bottom_bar/bubble_bottom_bar.dart';
import 'package:taskermg/common/tasks_page.dart';
import 'package:get/get.dart';
import 'package:taskermg/models/project.dart';
//import 'package:flutter_native_splash/flutter_native_splash.dart';

class ProyectDashboard extends StatefulWidget {
  const ProyectDashboard({Key? key, required this.project}) : super(key: key);
  final Project project;

  @override
  _ProyectDashboardState createState() => _ProyectDashboardState();
}

class _ProyectDashboardState extends State<ProyectDashboard> {
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
    FloatingActionButton taskFloatingBT = FloatingActionButton(
        onPressed: () async {
          await Get.to(() => const AddTaskPage());
          Get.put(TaskController()).getTasks();
        },
        backgroundColor: AppColors.secondaryColor,
        child:  Icon(Icons.add, color: AppColors.textColor, size: 36),
      );

    return Scaffold(
      body: <Widget>[
        TasksPage(),
        const Logs(),
        ProgressPage(),
      ][currentIndex],
      floatingActionButton: currentIndex == 0 ? taskFloatingBT : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BubbleBottomBar(
        backgroundColor: AppColors.secBackgroundColor,
        hasNotch: true,
        fabLocation: BubbleBottomBarFabLocation.end,
        opacity: 0.75,
        currentIndex: currentIndex,
        onTap: changePage,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(25),
          bottom: Radius.circular(14)
        ), //border radius doesn't work when the notch is enabled.
        elevation: 10,
        tilesPadding: const EdgeInsets.symmetric(
          vertical: 8.0,
        ),

        items: <BubbleBottomBarItem>[
          BubbleBottomBarItem(
            backgroundColor: AppColors.secondaryColor,
            icon: Icon(
              Icons.add_task,
              color: AppColors.backgroundColor,
            ),
            activeIcon: Icon(
              Icons.add_task,
              color: AppColors.secBackgroundColor,
            ),
            title: Text(
              "Tareas",
              style: TextStyle(
                color: AppColors.textColor,
              ),
            ),
          ),

          BubbleBottomBarItem(
              backgroundColor: AppColors.secondaryColor,
              icon: Icon(
                Icons.task,
                color: AppColors.backgroundColor,
              ),
              activeIcon: Icon(
                Icons.task,
                color: AppColors.secBackgroundColor,
              ),
              title: Text(
                "Tareas Asignadas",
                style: TextStyle(color: AppColors.textColor),
              )),
        ],
      ),
    );
  }
}