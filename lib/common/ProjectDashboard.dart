import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:taskermg/common/collaboratorsPage.dart';
import 'package:taskermg/common/edit_project.dart';
import 'package:taskermg/common/pages/logs.dart';
import 'package:taskermg/common/projects_page.dart';
import 'package:taskermg/common/tasks_page.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/models/project.dart';
import 'package:taskermg/controllers/project_controller.dart';
import 'package:taskermg/common/settings_page.dart';
import 'package:taskermg/controllers/task_controller.dart';

class ProyectDashboard extends StatefulWidget {
  const ProyectDashboard({Key? key, required this.project}) : super(key: key);
  final Project project;

  @override
  _ProyectDashboardState createState() => _ProyectDashboardState();
}

class _ProyectDashboardState extends State<ProyectDashboard> with SingleTickerProviderStateMixin {
  static var screenTitle = "Tareas".obs;
  static var selectedIndex = 0.obs;

  late TabController _tabController;

  bool imOwner = false;

  getprojectTitle() {
    return widget.project.name.toString();
  }

  TasksPage tasksPage = TasksPage();
  static LogActivityPage? logActivityPage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    logActivityPage = LogActivityPage(project: widget.project);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.index == 2) {
      logActivityPage = LogActivityPage(project: widget.project); // Reload log activity page
    }
    changePage(_tabController.index);
  }

  void changePage(int index) {
    selectedIndex.value = index;
    switch (selectedIndex.value) {
      case 0:
        screenTitle.value = "Tareas";
        break;
      case 1:
        screenTitle.value = "Colaboradores";
        break;
      case 2:
        screenTitle.value = "Registros";
        break;
      case 3:
        screenTitle.value = "Editar Proyecto";
        break;
    }
  }

  Future<Map<String, dynamic>> getTaskInfo(Project project) async {
    var taskController = TaskController();
    var tasks = await taskController.getTasks(project.projectID ?? project.locId);
    int totalTasks = tasks.length;
    int completedTasks = 0;
    for (var task in tasks) {
      if (task.status == 'Completada') {
        completedTasks++;
      }
    }
    double percentage = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return {
      'percentage': percentage,
      'tasks': totalTasks,
      'completed': completedTasks,
    };
  }

  Future<bool> _onWillPop() async {
    if (selectedIndex.value != 0) {
      changePage(0);
      return false; // Prevent exiting the app
    } else {
      return true; // Exit the app
    }
  }

  @override
  Widget build(BuildContext context) {
    var project = widget.project;
    imOwner = MainController.getVar("currentUser") == project.proprietaryID;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Container(
        color: AppColors.secBackgroundColor,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: AppColors.backgroundColor,
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.backgroundColor),
                onPressed: () {
                  if (selectedIndex.value != 0) {
                    changePage(0);
                  } else {
                    ProjectPage.projectController.getProjects();
                    Navigator.pop(context);
                  }
                },
              ),
              title: Obx(() => Text(screenTitle.value, style: headingStyleInv)),
              backgroundColor: AppColors.secBackgroundColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(30),
                ),
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
                  topLeft: Radius.circular(30),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30)),
                    color: AppColors.backgroundColor,
                  ),
                  child: Obx(() {
                    return IndexedStack(
                      index: selectedIndex.value,
                      children: [
                        tasksPage,
                        CollaboratorsPage(project: project),
                        logActivityPage!,
                        EditProjectScreen(project: project),
                      ],
                    );
                  }),
                ),
              ),
            ),
            endDrawer: CustomDrawer(project: widget.project, getTaskInfo: getTaskInfo, changePage: changePage),
          ),
        ),
      ),
    );
  }
}

class CustomDrawer extends StatelessWidget {
  final ProjectController projectController = Get.put(ProjectController());
  final Project project;
  final Future<Map<String, dynamic>> Function(Project) getTaskInfo;
  final Function(int) changePage;
  CustomDrawer({required this.project, required this.getTaskInfo, required this.changePage});
  bool imOwner() {
    return MainController.getVar("currentUser") == project.proprietaryID;
  }

  @override
  Widget build(BuildContext context) {
    projectController.getProjects();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30), bottomLeft: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), bottomLeft: Radius.circular(30)),
        ),
        backgroundColor: AppColors.backgroundColor2,
        child: Column(
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: getTaskInfo(project),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Error al cargar datos"),
                  );
                } else {
                  var taskInfo = snapshot.data!;
                  return ProjectDetailsHeader(
                    project: project,
                    taskInfo: taskInfo,
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.folder),
              title: Text("Tareas"),
              textColor: AppColors.textColor,
              onTap: () {
                changePage(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.contacts),
              title: Text("Colaboradores"),
              textColor: AppColors.textColor,
              onTap: () {
                changePage(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.local_activity),
              title: Text("Actividad"),
              textColor: AppColors.textColor,
              onTap: () {
                changePage(2);
                Navigator.pop(context);
              },
            ),
            SizedBox(
              height: 25,
            ),
            imOwner() ? ListTile(
              leading: Icon(Icons.settings),
              title: Text("Editar"),
              textColor: AppColors.textColor,
              onTap: () {
                changePage(3);
                Navigator.pop(context);
              },
            ): Container(),
          ],
        ),
      ),
    );
  }
}

class ProjectDetailsHeader extends StatelessWidget {
  final Project project;
  final Map<String, dynamic> taskInfo;

  ProjectDetailsHeader({required this.project, required this.taskInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
        ),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.fromRGBO(158, 0, 109, 1),
            Color.fromRGBO(90, 87, 255, 1),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.name ?? "Nombre del Proyecto",
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            project.description ?? "Descripción del Proyecto",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            "Fecha límite: ${project.deadline?.toIso8601String() ?? 'N/A'}",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 16),
          LinearPercentIndicator(
            animation: true,
            animationDuration: 1200,
            lineHeight: 20.0,
            percent: taskInfo['percentage'],
            center: Text(
              '${(taskInfo['percentage'] * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            progressColor: Color.fromRGBO(249, 2, 181, 1),
            backgroundColor: Color.fromRGBO(87, 1, 61, 1),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total de tareas",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "${taskInfo['tasks']}",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tareas completadas",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "${taskInfo['completed']}",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
