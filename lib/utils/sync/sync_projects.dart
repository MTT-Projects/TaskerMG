import 'dart:convert';
import 'package:mysql1/mysql1.dart';
import 'package:taskermg/controllers/maincontroller.dart';
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
        }
      }

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
        var hasDeletion = await hasDeletionLog(projectMap['projectID'] ?? projectMap['locId']);
        if (!hasDeletion) {
          var creationActivity = await getCreationActivityByProjectID(projectMap['projectID'] ?? projectMap['locId']);
          if (creationActivity != null) {
            if (creationActivity['isSynced'] == 0) {
              await handleRemoteProjectInsert(projectMap);
            }
          }
        } else {
          await markActivityLogAsSyncedByProjectId(projectMap['projectID'] ?? projectMap['locId']);
        }
      }

      var unsyncedProjectUpdates = await LocalDB.queryUnsyncedUpdates('project');
      AppLog.d("Proyectos sin actualizar: ${jsonEncode(unsyncedProjectUpdates)}");
      for (var actMap in unsyncedProjectUpdates) {
        var details = jsonDecode(actMap['activityDetails']);
        var hasDeletion = await hasDeletionLog(details['projectID'] ?? details['locId']);
        if (!hasDeletion) {
          var creationActivity = await getCreationActivityByProjectID(details['projectID'] ?? details['locId']);
          if (creationActivity != null) {
            if (creationActivity['isSynced'] == 0) {
              await handleRemoteProjectUpdate(actMap);
            }
          } else {
            await handleRemoteProjectUpdate(actMap);
          }
        } else {
          await markActivityLogAsSyncedByProjectId(details['projectID']);
        }
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

  //get creation activity by projectID
  static Future<Map<String, dynamic>?> getCreationActivityByProjectID(
      int projectID) async {
    var activities = await LocalDB.rawQuery(
      "SELECT * FROM activityLog WHERE activityType = 'create'",
    );
    for (Map<String, dynamic> activity in activities) {
      var details = jsonDecode(activity['activityDetails']);

      var actProjectId = details['locId'];
      if (details['table'] == 'project' && actProjectId == projectID) {
        return activity;
      }
    }
    return null;
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
    var projectMap = <String, dynamic>{};
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

    //check last update in remote and update only if local is newer
    var remoteProject = await DBHelper.query(
      "SELECT * FROM project WHERE projectID = ?",
      [projectMap['projectID']],
    );
    if (remoteProject.isNotEmpty) {
      var remoteLastUpdate = remoteProject.first['lastUpdate'];

      var localLastUpdate = DateTime.parse(projectMap['lastUpdate']);
      if (remoteLastUpdate.isAfter(localLastUpdate)) {
        AppLog.d("Proyecto remoto más reciente, no se actualizará.");
        return;
      }
    }

    var response = await DBHelper.query(
      "UPDATE project SET name = ?, description = ?, deadline = ?, proprietaryID = ?, lastUpdate = ? WHERE projectID = ?",
      [name, description, deadline, proprietaryID, lastUpdate, projectMap['projectID']],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);
    } else {
      AppLog.e("Error updating project in remote database: $response");
    }
  }

  static Future<void> handleRemoteProjectDeletion(Map<String, dynamic> deletion) async {
    var activityDetails = jsonDecode(deletion['activityDetails']);
    var remoteID = activityDetails['projectID'] ?? activityDetails['locId'];
    // Verificar si el proyecto existe en la base de datos remota
    var existProject = await DBHelper.query(
      "SELECT * FROM project WHERE projectID = ?",
      [remoteID],
    );
    var projectMap = existProject.isNotEmpty ? existProject.first : null;
    if (projectMap != null) {
      await DBHelper.query(
        "DELETE FROM project WHERE projectID = ?",
        [remoteID],
      );
    }
    var delLocId = deletion['locId'];
    await LocalDB.markActivityLogAsSynced(delLocId);
  }

  static Future<bool> hasDeletionLog(int projectId) async {
    var deletions = await LocalDB.queryUnsyncedDeletions('project');
    for (var deletion in deletions) {
      var details = jsonDecode(deletion['activityDetails']);
      if (details['projectID'] == projectId || details['locId'] == projectId) {
        //establecer a la actividad de creacion como isSynced
        var creationActivity = await getCreationActivityByProjectID(projectId);
        if (creationActivity != null) {
          await LocalDB.markActivityLogAsSynced(creationActivity['locId']);
        }
        return true;
      }
    }
    return false;
  }

  static Future<void> markActivityLogAsSyncedByProjectId(int projectId) async {
    // Marcar actividades de creación como sincronizadas
    var activities = await LocalDB.queryUnsyncedActivityLogs();
    // Filtrar actividades de creación y actualizacion
    var filAct = [];
    for (var act in activities) {
      if (act['activityType'] == 'create' || act['activityType'] == 'update') {
        filAct.add(act);
      }
    }

    for (var activity in filAct) {
      var data = jsonDecode(activity['activityDetails']);
      if (data['projectID'] == projectId || data['locId'] == projectId) {
        var updated = await LocalDB.markActivityLogAsSynced(activity['locId']);
        AppLog.d("Actividad de creación marcada como sincronizada: $updated");
      }
    }

    // Marcar actividades de actualización como sincronizadas
    var updates = await LocalDB.queryUnsyncedUpdates('project');
    for (var update in updates) {
      var details = jsonDecode(update['activityDetails']);
      if (details['projectID'] == projectId || details['locId'] == projectId) {
        await LocalDB.markActivityLogAsSynced(update['locId']);
      }
    }

    // Marcar actividades de eliminación como sincronizadas
    var deletions = await LocalDB.queryUnsyncedDeletions('project');
    for (var deletion in deletions) {
      var details = jsonDecode(deletion['activityDetails']);
      if (details['projectID'] == projectId || details['locId'] == projectId) {
        await LocalDB.markActivityLogAsSynced(deletion['locId']);
      }
    }
  }
}
