// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taskermg/common/add_project.dart';
import 'package:taskermg/common/projects_page.dart';
import 'package:taskermg/common/settings_page.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/controllers/task_controller.dart';
import 'package:bubble_bottom_bar/bubble_bottom_bar.dart';
import 'package:taskermg/common/add_task_bar.dart';
import 'package:taskermg/common/pages/logs.dart';
import 'package:taskermg/common/pages/progress.dart';
import 'package:taskermg/utils/Dashboardcontroller.dart';
import 'package:taskermg/views/globalheader.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final DashboardController _dashboardController =
      Get.put(DashboardController());
  final ProjectPage projectPage = ProjectPage();

  RxInt currentIndex = 0.obs;
  RxString screenTitle = "Mis Proyectos".obs;

  @override
  void initState() {
    super.initState();
    currentIndex.value = 0;
  }

  void changePage(int? index) {
    currentIndex.value = index!;
    switch (currentIndex.value) {
      case 0:
        screenTitle.value = "Mis Proyectos";
        break;
      case 1:
        screenTitle.value = "Contactos";
        break;
      case 2:
        screenTitle.value = "Solicitudes";
        break;
    }
  }

  AppBar header()  {
    return globalheader(AppColors.secBackgroundColor, screenTitle.value);
  }

  @override
  Widget build(BuildContext context) {
    FloatingActionButton projectFloatingBT = FloatingActionButton(
      onPressed: () async {
        await Get.to(() => AddProjectPage());
        ProjectPage.projectController.getProjects();
      },
      backgroundColor: AppColors.secondaryColor,
      child: Icon(Icons.add, color: AppColors.textColor, size: 36),
    );

    return WillPopScope(
      onWillPop: () async {
        ProjectPage.projectController.getProjects();
        return true;
      },
      child: Container(
        color: AppColors.secBackgroundColor,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: AppColors.backgroundColor,
            appBar: header(),
            body: Container(
                decoration: BoxDecoration(color: AppColors.secBackgroundColor),
                child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                    ),
                    child: Container(
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.only(topLeft: Radius.circular(20)),
                            color: AppColors.backgroundColor),
                        child: Obx(() {
                          return IndexedStack(
                            index: currentIndex.value,
                            children: [
                              projectPage,
                              Center(
                                child: Text("Contactos"),
                              ),
                              Center(
                                child: Text("Solicitudes"),
                              ),
                            ],
                          );
                        })))), 
            floatingActionButton: currentIndex.value == 0 ? projectFloatingBT : null,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endDocked,
            bottomNavigationBar: Obx(() {
              return BubbleBottomBar(
                backgroundColor: AppColors.secBackgroundColor,
                hasNotch: true,
                fabLocation: BubbleBottomBarFabLocation.end,
                opacity: 0.75,
                currentIndex: currentIndex.value,
                onTap: changePage,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                  bottom: Radius.circular(14),
                ),
                elevation: 10,
                tilesPadding: const EdgeInsets.symmetric(vertical: 8.0),
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
                      "Mis",
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
                      "Todos",
                      style: TextStyle(color: AppColors.textColor),
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
                      "Solicitudes.",
                      style: TextStyle(color: AppColors.textColor),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
