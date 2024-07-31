import 'dart:convert';

import 'package:get/get.dart';
import 'package:taskermg/controllers/sync_controller.dart';
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
    //sync tables
    await SyncController.pushData();
  }

  Future<void> getProjects() async {
    AppLog.d("Getting projects for User: ${MainController.getVar('userID')}");
    final userID = MainController.getVar('userID');
    final localDBinit = MainController.getVar('initLDB');
    var whereAdd = '';
    bool onlyMine = MainController.getVar('onlyMine') ?? false;

    if (userID != null && localDBinit == true) {
      List<Map<String, dynamic>> projects = [];
      if (onlyMine) {
        AppLog.d("Getting only mine projects with propetaryID: $userID");
        projects = await LocalDB.rawQuery('''
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
          INNER JOIN 
              userProject up ON p.projectID = up.projectID
          WHERE 
              p.proprietaryID = ?
              AND up.userID = ?''', [userID, userID]);
      } else {
        projects = await LocalDB.rawQuery('''
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
          u.userID = ? AND
          p.proprietaryID <> ?
      ''', [userID, userID]);
      }

      if (projects.isEmpty) {
        AppLog.d("No projects found for user $userID");
        projectList.clear();
      } else {
        projectList
            .assignAll(projects.map((data) => Project.fromJson(data)).toList());
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
      }
    } else {
      AppLog.d("No user selected or LocalDB not initialized");
      projectList.clear();
    }
  }

  Future<void> deleteProject(Project project) async {
    AppLog.d(
        "Deleting project with locId: ${project.locId} and data ${project.toJson()}");

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
    var tasks = await LocalDB.query('tasks',
        where: 'projectID = ?',
        whereArgs: [project.projectID ?? project.locId]);
    for (var task in tasks) {
      await TaskController.deleteTask(Task.fromJson(task));
    }

    // Eliminar relaciones de usuario-proyecto
    await LocalDB.delete('userProject',
        where: 'projectID = ?',
        whereArgs: [project.projectID ?? project.locId]);

    // Eliminar el proyecto
    await LocalDB.delete('project',
        where: 'locId = ?', whereArgs: [project.locId]);
    getProjects();

    //sync tables
    await SyncController.pushData();
  }

  Future<bool> updateProject(Project project) async {
    AppLog.d(
        "Updating project with locId: ${project.locId} and data ${project.toJson()}");
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
    //sync tables
    await SyncController.pushData();
    return res == 1;
  }

  static getCollaboratorsNumber(int? proyectID) async {
    var response = await LocalDB.rawQuery('''
      SELECT 
        COUNT(userID) as collaborators 
      FROM 
        userProject 
      WHERE 
        projectID = ? 
    ''', [proyectID]);
    return response[0]['collaborators'];
  }

  static getProjectName(projectID) async {
    //return project name
    var result = await LocalDB.rawQuery(
      'SELECT name FROM project WHERE projectID = ?',
      [projectID],
    );
    return result[0]['name'];
  }
}

class ProjectGoalController extends GetxController {
  var goals = <ProjectGoal>[].obs;

  @override
  void onReady() {
    try {
      getGoals();
    } catch (e) {
      AppLog.e("Error getting project goals: $e");
    }
    super.onReady();
  }

  Future<void> addProjectGoal(ProjectGoal projectGoal) async {
    int locId = await LocalDB.insertProjectGoal(projectGoal);
    projectGoal.locId = locId;
    goals.add(projectGoal);

    await LocalDB.insertActivityLog(ActivityLog(
      userID: MainController.getVar('userID'),
      projectID: projectGoal.projectID,
      activityType: 'create',
      activityDetails: {
        'table': 'projectGoal',
        'locId': locId,
      },
      timestamp: DateTime.now().toUtc(),
      lastUpdate: DateTime.now().toUtc(),
    ));
    AppLog.d(
        "ProjectGoal added with locId: $locId with data: ${projectGoal.toJson()}");

    await SyncController.pushData();
  }

  Future<void> getGoals() async {
    AppLog.d("Getting goals for User: ${MainController.getVar('userID')}");
    final userID = MainController.getVar('userID');
    final localDBinit = MainController.getVar('initLDB');

    if (userID != null && localDBinit == true) {
      List<Map<String, dynamic>> goals = await LocalDB.rawQuery('''
        SELECT 
          pg.locId,
          pg.goalID, 
          pg.projectID, 
          pg.goalDescription, 
          pg.isCompleted,
          pg.lastUpdate
        FROM 
          projectGoal pg
        JOIN 
          project p ON pg.projectID = p.projectID
        JOIN 
          userProject up ON p.projectID = up.projectID
        WHERE 
          up.userID = ?
      ''', [userID]);

      if (goals.isEmpty) {
        AppLog.d("No goals found for user $userID");
        this.goals.clear();
      } else {
        this.goals.assignAll(
            goals.map((data) => ProjectGoal.fromJson(data)).toList());
        AppLog.d("Goals: ${jsonEncode(this.goals)}");
      }
    } else {
      AppLog.d("No user selected or LocalDB not initialized");
      this.goals.clear();
    }
  }

  Future<void> deleteGoal(ProjectGoal projectGoal) async {
    AppLog.d(
        "Deleting goal with locId: ${projectGoal.locId} and data ${projectGoal.toJson()}");

    await LocalDB.insertActivityLog(ActivityLog(
      userID: MainController.getVar('userID'),
      projectID: projectGoal.projectID,
      activityType: 'delete',
      activityDetails: {
        'table': 'projectGoal',
        'locId': projectGoal.locId,
        'goalID': projectGoal.goalID
      },
      timestamp: DateTime.now().toUtc(),
      lastUpdate: DateTime.now().toUtc(),
    ));

    await LocalDB.delete('projectGoal',
        where: 'locId = ?', whereArgs: [projectGoal.locId]);
    goals.remove(projectGoal);

    await SyncController.pushData();
  }

  Future<bool> updateGoal(ProjectGoal projectGoal) async {
    AppLog.d(
        "Updating goal with locId: ${projectGoal.locId} and data ${projectGoal.toJson()}");
    projectGoal.lastUpdate = DateTime.now().toUtc();

    var res = await LocalDB.update(
      "projectGoal",
      projectGoal.toMap(),
      where: 'locId = ?',
      whereArgs: [projectGoal.locId],
    );

    await LocalDB.insertActivityLog(ActivityLog(
      userID: MainController.getVar('userID'),
      projectID: projectGoal.projectID,
      activityType: 'update',
      activityDetails: {
        'table': 'projectGoal',
        'locId': projectGoal.locId,
        'goalID': projectGoal.goalID,
      },
      timestamp: DateTime.now().toUtc(),
      lastUpdate: DateTime.now().toUtc(),
    ));

    int index = goals.indexWhere((goal) => goal.locId == projectGoal.locId);
    if (index != -1) {
      goals[index] = projectGoal;
    }

    await SyncController.pushData();
    return res == 1;
  }

  Future<List<ProjectGoal>> getGoalsByProjectId(int projectId) async {
    try {
      List<Map<String, dynamic>> maps = await LocalDB.query(
        'projectGoal',
        where: 'projectID = ?',
        whereArgs: [projectId],
      );
      return maps.isNotEmpty
          ? maps.map((goal) => ProjectGoal.fromJson(goal)).toList()
          : [];
    } catch (e) {
      AppLog.e("Error getting project goals by projectId: $e");
      return [];
    }
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
