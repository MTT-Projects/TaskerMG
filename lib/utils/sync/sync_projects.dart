import 'dart:convert';

import 'package:mysql1/mysql1.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/project_controller.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/project.dart';
import 'package:taskermg/utils/AppLog.dart';
import 'package:intl/intl.dart';

class SyncProjects {

  static String formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

  static Future<void> pullProjects() async {
    var userID = MainController.getVar('currentUser');
    try {
      var result = await DBHelper.query('''SELECT 
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
          userProject up ON p.projectID = up.projectID
        JOIN 
          user u ON up.userID = u.userID
        WHERE 
          u.userID = ?''', [userID]);

      var remoteProjects = result.map((projectMap) => projectMap['projectID']).toList();
      // Fetch local projects
      var localProjects = await LocalDB.queryProjects();
      if(localProjects.isEmpty) {
        AppLog.d("No hay proyectos locales.");
      } else {
      var localProjectIDs = localProjects.map((project) => project['projectID']).toList();

      // Detect deleted projects
      for (var localProjectID in localProjectIDs) {
        if (!remoteProjects.contains(localProjectID)) {
          await LocalDB.rawDelete(
            "DELETE FROM project WHERE projectID = ?",
            [localProjectID],
          );
          AppLog.d("Proyecto con ID $localProjectID marcado como eliminado.");
        }
      }}

      for (var projectMap in result) {
        var projectMapped = Project(
          projectID: projectMap['projectID'],
          name: projectMap['name'],
          description: projectMap['description'].toString(),
          deadline: projectMap['deadline'],
          proprietaryID: projectMap['proprietaryID'], 
          creationDate: projectMap['creationDate'],
          lastUpdate: projectMap['lastUpdate'],
        ).toJson();
        await handleProjectSync(projectMapped);
      }

      AppLog.d("Proyectos obtenidos exitosamente.");
    } catch (e) {
      AppLog.e("Error al obtener proyectos: $e");
    }
  }

  static Future<void> pushProjects() async {
    try {

      var unsyncedProjects = await LocalDB.queryUnsyncedProjects();
      AppLog.d("Proyectos sin sincronizar: ${jsonEncode(unsyncedProjects)}");
      for (var projectMap in unsyncedProjects) {
        await handleRemoteProjectInsert(projectMap);
      }

      var unsyncedProjectUpdates = await LocalDB.queryUnsyncedUpdates('project');
      AppLog.d("Proyectos sin actualizar: ${jsonEncode(unsyncedProjectUpdates)}");
      for (var actMap in unsyncedProjectUpdates) {
        await handleRemoteProjectUpdate(actMap);
      }

      var unsyncedDeletions = await LocalDB.queryUnsyncedDeletions('project');
      AppLog.d("Proyectos sin eliminar: ${jsonEncode(unsyncedDeletions)}");
      for (var deletion in unsyncedDeletions) {
        await handleRemoteProjectDeletion(deletion);
      }

      AppLog.d("Proyectos enviados exitosamente.");
    } catch (e) {
      AppLog.e("Error al enviar proyectos: $e");
    }
  }

  static Future<void> handleProjectSync(Map<String, dynamic> projectMap) async {
    var localProject = await LocalDB.queryProjectByRemoteID(projectMap['projectID']);
    if (localProject == null) {
      AppLog.d("Local proyect not found, creating a new one");
      await LocalDB.insertProject(Project.fromJson(projectMap));
    } else {
      projectMap['locId'] = localProject['locId'];
      if (DateTime.parse(projectMap['lastUpdate']).isAfter(DateTime.parse(localProject['lastUpdate']))) {
        await LocalDB.updateProject(Project.fromJson(projectMap));
      }
    }
  }

  static Future<void> handleRemoteProjectInsert(Map<String, dynamic> projectMap) async {
    String name = projectMap['name'];
    String description = projectMap['description'];
    String deadline = formatDateTime(DateTime.parse(projectMap['deadline']));
    String proprietaryID = projectMap['proprietaryID'].toString();
    String creationDate = formatDateTime(DateTime.parse(projectMap['creationDate']));
    String lastUpdate = formatDateTime(DateTime.parse(projectMap['lastUpdate']));

    var response = await DBHelper.query(
      "INSERT INTO project (name, description, deadline, proprietaryID, creationDate, lastUpdate) VALUES (?, ?, ?, ?, ?, ?)",
      [name, description, deadline, proprietaryID, creationDate, lastUpdate],
    );

    if (response is Results) {
      var insertId = response.insertId;
      if (insertId != null) {
        await LocalDB.updateProjectSyncStatus(projectMap['locId'], insertId);
      }
    } else {
      AppLog.e("Error inserting project in remote database: $response");
    }
  }

  static Future<void> handleRemoteProjectUpdate(Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var projectMap = Map<String, dynamic>();
    //get projectMap from activityDetails and localdb 
    if(actDetails['projectID'] != null){
      projectMap = (await LocalDB.queryProjectByRemoteID(actDetails['projectID']))!;
    } else {
      projectMap = (await LocalDB.queryProjectByLocalID(actDetails['locId']))!;
    }

    String name = projectMap['name'];
    String description = projectMap['description'];
    String deadline = formatDateTime(DateTime.parse(projectMap['deadline']));
    String proprietaryID = projectMap['proprietaryID'].toString();
    String creationDate = formatDateTime(DateTime.parse(projectMap['creationDate']));
    String lastUpdate = formatDateTime(DateTime.parse(projectMap['lastUpdate']));

    var response;
    response = await DBHelper.query(
      "UPDATE project SET name = ?, description = ?, deadline = ?, proprietaryID = ?, lastUpdate = ? WHERE projectID = ?",
      [name, description, deadline, proprietaryID, lastUpdate, projectMap['projectID']],
    );

    if (response is Results) {
      var insertId = response.insertId;
      if (insertId != null) {
        await LocalDB.markActivityLogAsSynced(projectMap['locId']);
      }
    } else {
      AppLog.e("Error inserting/updating project in remote database: $response");
    }
  }

  static Future<void> handleRemoteProjectDeletion(Map<String, dynamic> deletion) async {
    var activityDetails = jsonDecode(deletion['activityDetails']);
    var remoteID = activityDetails['projectID'] ?? activityDetails['locId'];
    await DBHelper.query(
      "DELETE FROM project WHERE projectID = ?",
      [remoteID],
    );
    var delLocId = deletion['locId'];
    await LocalDB.markActivityLogAsSynced(delLocId);
  }
}
