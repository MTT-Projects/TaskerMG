import 'dart:convert';

import 'package:get/get.dart';
import 'package:taskermg/controllers/task_controller.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/activity_log.dart';
import 'package:taskermg/models/project.dart';
import 'package:taskermg/models/task.dart';
import 'package:taskermg/utils/AppLog.dart';

import 'dbRelationscontroller.dart';
import 'maincontroller.dart';

class ProjectController extends GetxController {
  @override
  void onReady() {
    try {
      getProjects();
    } catch (e) {
      AppLog.e("Error getting projects: $e");
    }
    super.onReady();
  }

  var projectList = <Project>[].obs;

  Future<void> addProject(Project project) async {
    int locId = await LocalDB.insertProject(project);

    // Asignar el proyecto al usuario actual
    DbRelationsCtr.addUserProject(MainController.getVar('userID'), locId);

    // Registrar la actividad
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MainController.getVar('userID'),
      projectID: locId,
      activityType: 'create',
      activityDetails: {
        'table': 'project',
        'locId': locId,
      },
      timestamp: DateTime.now().toUtc(),
      lastUpdate: DateTime.now().toUtc(),
    ));
    AppLog.d("Project added with locId: $locId with data: ${project.toJson()}");
  }

  Future<void> getProjects() async {
    AppLog.d("Getting projects for User: ${MainController.getVar('userID')}");
    final userID = MainController.getVar('userID');
    final localDBinit = MainController.getVar('initLDB');

    if (userID != null && localDBinit == true) {
      List<Map<String, dynamic>> projects = await LocalDB.rawQuery('''
        SELECT 
          p.locId,
          p.projectID, 
          p.name, 
          p.description, 
          p.deadline, 
          p.proprietaryID,
          p.creationDate, 
          p.lastUpdate 
        FROM 
          project p
        JOIN 
          userProject up 
          ON (CASE 
                WHEN p.projectID IS NOT NULL 
                THEN p.projectID = up.projectID 
                ELSE p.locId = up.projectID 
              END)
        JOIN 
          user u 
          ON u.userID = up.userID 
        WHERE 
          u.userID = ? 
      ''', [userID]);
      projectList.assignAll(projects.map((data) => Project.fromJson(data)).toList());
      AppLog.d("Projects: ${jsonEncode(projectList)}");
      //allprojects
      var res2 = await LocalDB.rawQuery('''
        SELECT 
          * 
        FROM 
          project 
      ''', []);
      AppLog.d("All Projects: ${jsonEncode(res2)}");
      //applog relations
      var res = await LocalDB.rawQuery('''
        SELECT 
          * 
        FROM 
          userProject 
        WHERE 
          userID = ? 
      ''', [userID]);
      AppLog.d("UserProject: ${jsonEncode(res)}");
    } else {
      AppLog.d("No user selected or LocalDB not initialized");
      projectList.clear();
    }
  }

  Future<void> deleteProject(Project project) async {
    AppLog.d("Deleting project with locId: ${project.locId} and data ${project.toJson()}");

    // Registrar la actividad antes de la eliminación
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MainController.getVar('userID'),
      projectID: project.locId,
      activityType: 'delete',
      activityDetails: {
        'table': 'project',
        'locId': project.locId,
        'projectID': project.projectID
      },
      timestamp: DateTime.now().toUtc(),
      lastUpdate: DateTime.now().toUtc(),
    ));

    // Eliminar relaciones de task
    var tasks = await LocalDB.query('tasks', where: 'projectID = ?', whereArgs: [project.projectID ?? project.locId]);
    for (var task in tasks) {
      await TaskController.deleteTask(Task.fromJson(task));
    }

    // Eliminar relaciones de usuario-proyecto
    await LocalDB.delete('userProject', where: 'projectID = ?', whereArgs: [project.projectID ?? project.locId]);

    // Eliminar el proyecto
    await LocalDB.delete('project', where: 'locId = ?', whereArgs: [project.locId]);    
    getProjects();
  }

  Future<bool> updateProject(Project project) async {
    AppLog.d("Updating project with locId: ${project.locId} and data ${project.toJson()}");
    project.lastUpdate = DateTime.now().toUtc();

    var res = await LocalDB.update(
      "project",
      project.toMap(),
      where: 'locId = ?',
      whereArgs: [project.locId],
    );
     // Registrar la actividad
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MainController.getVar('userID'),
      projectID: project.locId,
      activityType: 'update',
      activityDetails: {
        'table': 'project',
        'locId': project.locId,
        'projectID': project.projectID,
      },
      timestamp: DateTime.now().toUtc(),
      lastUpdate: DateTime.now().toUtc(),
    ));

    getProjects();
    return res == 1;
  }
}

class ProjectGoalController{
  //add
  void addProjectGoal(ProjectGoal projectGoal) async {
    int locId = await LocalDB.insertProjectGoal(projectGoal);
    AppLog.d("ProjectGoal added with locId: $locId with data: ${projectGoal.toJson()}");
  }

  static updateProjectID(int locId, int projectId) {
    LocalDB.update(
      "projectGoal",
      {'projectID': projectId},
      where: 'locId = ?',
      whereArgs: [locId],
    );
  }
}
