// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:taskermg/common/ProjectDashboard.dart';
import 'package:taskermg/common/edit_project.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/project_controller.dart';
import 'package:taskermg/controllers/task_controller.dart';
import 'package:taskermg/models/project.dart';
import 'package:taskermg/common/theme.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'add_project.dart';

class ProjectPage extends StatefulWidget {
  static final ProjectController projectController = Get.put(ProjectController());

  @override
  _ProjectPageState createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ProjectPage.projectController.getProjects();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ProjectPage.projectController.getProjects();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Obx(() {
        return ListView.builder(
          itemCount: ProjectPage.projectController.projectList.length,
          itemBuilder: (context, index) {
            Project project = ProjectPage.projectController.projectList[index];
            return ProjectCard(project: project, PC: ProjectPage.projectController);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Get.to(() => AddProjectPage());
          ProjectPage.projectController.getProjects();
        },
        backgroundColor: Colors.purple,
        child: Icon(Icons.add, size: 36),
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final Project project;
  final ProjectController PC;

  const ProjectCard({required this.project, required this.PC});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getTaskInfo(project),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('No hay datos disponibles'));
        }

        var taskInfo = snapshot.data!;
        var percentage = taskInfo['percentage'] ?? 0.0;
        var totalTasks = taskInfo['tasks'] ?? 0;
        var completedTasks = taskInfo['completed'] ?? 0;

        return InkWell(
          onTap: () async {
            MainController.setVar('currentProject', project.projectID ?? project.locId);
            await Get.to(() => ProyectDashboard(project: project));
            ProjectPage.projectController.getProjects();
          },
          onLongPress:() async {
            //ir a la pantalla de edicion
            await Get.to(() => EditProjectScreen(project: project));
            ProjectPage.projectController.getProjects();
          },
          child: Container(
            margin: EdgeInsetsDirectional.only(top: 5, start: 10, end: 10, bottom: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondaryColor,
                  AppColors.primaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              color: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name ?? 'TÍTULO',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            project.description ?? 'Descripción...',
                            style: TextStyle(
                                fontSize: 16, color: Colors.white70),
                                maxLines: 2,
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.white70),
                              SizedBox(width: 4),
                              Text(
                                DateFormat('dd-MM-yyyy').format(
                                    project.deadline ?? DateTime.now().toUtc()),
                                style: TextStyle(color: Colors.white70),
                              ),
                              SizedBox(width: 16),
                              Icon(Icons.group, color: Colors.white70),
                              SizedBox(width: 4),
                              Text(
                                '25', // Ejemplo de número de personas
                                style: TextStyle(color: Colors.white70),
                              ),
                              SizedBox(width: 16),
                              Icon(Icons.check_circle, color: Colors.white70),
                              SizedBox(width: 4),
                              Text(
                                '$totalTasks', // Número de tareas
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    CircularPercentIndicator(
                      animation: true,
                      animationDuration: 1200,
                      radius: 75,
                      lineWidth: 8,
                      percent: percentage,
                      center: Text(
                        '${(percentage * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      progressColor: Color.fromRGBO(249, 2, 181, 1),
                      backgroundColor: Color.fromRGBO(87, 1, 61, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<Map<String, dynamic>> getTaskInfo(Project project) async {
  var taskController = TaskController();
  var tasks = await taskController
      .getTasks(project.projectID ?? project.locId); // Usa el ID del proyecto
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
