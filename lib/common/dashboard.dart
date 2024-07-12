// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taskermg/common/projects_page.dart';
import 'package:taskermg/common/settings_page.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/controllers/project_controller.dart';
import 'package:taskermg/utils/Dashboardcontroller.dart';

class Dashboard extends StatelessWidget {
  final DashboardController _dashboardController = Get.put(DashboardController());
  final ProjectPage projectPage = ProjectPage();

  

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ProjectPage.projectController.getProjects();
        return true;
      },
      child: Container(
        color: context.theme.secondaryHeaderColor,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: AppColors.backgroundColor,
            appBar: AppBar(
              title: Text('DASHBOARD', style: headingStyleInv),
              backgroundColor: AppColors.secBackgroundColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(50),
                    bottomRight: Radius.circular(50)),
              ),
              elevation: 0,
              actions: [
                Builder(
                  builder: (context) {
                    return IconButton(
                      icon: Icon(Icons.menu, color: AppColors.backgroundColor),
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                    );
                  },
                ),
              ],
            ),
            body: Container(
                decoration: BoxDecoration(color: AppColors.secBackgroundColor),
                child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                    ),
                    child: Container(
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.only(topLeft: Radius.circular(40)),
                            color: AppColors.backgroundColor),
                        child: Obx(() {
                          return IndexedStack(
                            index: _dashboardController.selectedIndex.value,
                            children: [
                              projectPage,
                              Center(
                                  child: Text('Pantalla de Contactos',
                                      style: headingStyle)),
                              SettingsScr(),
                            ],
                          );
                        })))),
            endDrawer: CustomDrawer(),
          ),
        ),
      ),
    );
  }
}

class CustomDrawer extends StatelessWidget {
  final DashboardController _dashboardController = Get.find();
final ProjectController projectController = Get.put(ProjectController());
  @override
  Widget build(BuildContext context) {
    projectController.getProjects();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(50), bottomLeft: Radius.circular(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent
                .withOpacity(0.5), // Color de la sombra (neón)
            spreadRadius: 1, // Extensión del efecto neón
            blurRadius: 3, // Radio de desenfoque del efecto neón
          ),
        ],
      ),
      child: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(50), bottomLeft: Radius.circular(50)),
        ),
        backgroundColor: AppColors.backgroundColor2,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text("Usuario"),
              accountEmail: Text("usuario@example.com"),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(50)),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color.fromRGBO(158, 0, 109, 1),
                    Color.fromRGBO(90, 87, 255, 1),
                  ],
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundImage: AssetImage("Assets/images/profile.png"),
              ),
              otherAccountsPictures: [
                IconButton(
                  icon: Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    _dashboardController.changePage(2);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            ListTile(
              leading: Icon(Icons.folder),
              title: Text("Proyectos"),
              textColor: AppColors.textColor,
              onTap: () {
                _dashboardController.changePage(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.contacts),
              title: Text("Contactos"),
              textColor: AppColors.textColor,
              onTap: () {
                _dashboardController.changePage(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Ajustes"),
              textColor: AppColors.textColor,
              onTap: () {
                _dashboardController.changePage(2);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
