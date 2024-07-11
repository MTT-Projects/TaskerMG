import 'dart:convert';

import 'package:get/get.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/activity_log.dart';
import 'package:taskermg/utils/AppLog.dart';
import '../models/dbRelations.dart';
import '../models/project.dart';

import 'dbRelationscontroller.dart';
import 'maincontroller.dart';

class ProjectController extends GetxController {
  // ignore: non_constant_identifier_names
  MainController MC = MainController();

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
    DbRelationsCtr.addUserProject(MC.getVar('userID'), project.projectID ?? locId);

    // Registrar la actividad
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MC.getVar('userID'),
      projectID: locId,
      activityType: 'create',
      activityDetails: {
        'table': 'project',
        'locId': locId,
      },
      timestamp: DateTime.now(),
      lastUpdate: DateTime.now(),
    ));
    AppLog.d("Project added with locId: $locId with data: ${project.toJson()}");
  }

  void getProjects() async {
    AppLog.d("Getting projects for User: ${MC.getVar('userID')}");
    final userID = MC.getVar('userID');
    final localDBinit = MC.getVar('initLDB');

    if (userID != null && localDBinit == true) {
      //applog all projects
      List<Map<String, dynamic>> allprojects = await LocalDB.db.rawQuery('''
        SELECT *
        FROM 
          project p  
      ''');
      //list all userproject
      List<Map<String, dynamic>> alluserprojects = await LocalDB.db.rawQuery('''
        SELECT *
        FROM 
          userProject up  
      ''');

      AppLog.d("All Projects: ${jsonEncode(allprojects)}");
      AppLog.d("All UserProjects: ${jsonEncode(alluserprojects)}");

      List<Map<String, dynamic>> projects = await LocalDB.db.rawQuery('''
        SELECT 
          p.locId,
          p.projectID, 
          p.name, 
          p.description, 
          p.deadline, 
          p.creationDate, 
          p.lastUpdate 
        FROM 
          project p
        JOIN 
          userProject up 
          ON (CASE 
                WHEN p.projectID IS NOT NULL THEN p.projectID = up.projectID 
                ELSE p.locId = up.projectID 
              END)
        JOIN 
          user u 
          ON (CASE 
                WHEN u.userID IS NOT NULL THEN u.userID = up.userID 
                ELSE u.userID = up.locId 
              END)
        WHERE 
          u.userID = ? 
      ''', [userID]);
      projectList
          .assignAll(projects.map((data) => Project.fromJson(data)).toList());
      
    } else {
      AppLog.d("No user selected or LocalDB not initialized");
      projectList
          .clear(); // Limpiar la lista si no hay un usuario actual seleccionado
    }
  }

  void deleteProject(Project project) async {
    AppLog.d("Deleting project with locId: ${project.locId} and data ${project.toJson()}");
    await LocalDB.db.rawQuery(
      'DELETE FROM project WHERE locId = ?',
      [project.locId],
    );

    // Registrar la actividad
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MC.getVar('userID'),
      projectID: project.locId,
      activityType: 'delete',
      activityDetails: {
        'table': 'project',
        'locId': project.locId,
      },
      timestamp: DateTime.now(),
      lastUpdate: DateTime.now(),
    ));
    getProjects();
  }

  void updateProject(Project project) async {
    await LocalDB.db.update(
      "project",
      project.toMap(),
      where: 'locId = ?',
      whereArgs: [project.locId],
    );

    
    getProjects();
  }
}
