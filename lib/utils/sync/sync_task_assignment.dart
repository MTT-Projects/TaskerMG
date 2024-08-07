import 'dart:convert';
import 'package:googleapis/admob/v1.dart';
import 'package:mysql1/mysql1.dart';
import 'package:taskermg/controllers/conecctionChecker.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/task_controller.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/dbRelations.dart';
import 'package:taskermg/utils/AppLog.dart';
import 'package:intl/intl.dart';

class SyncTaskAssignment {
  static String formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

  static Future<void> pullTaskAssignments() async {
    var userID = MainController.getVar('currentUser');
    try {
      var result = await DBHelper.query('''
        SELECT 
          ta.assignmentID, 
          ta.taskID, 
          ta.userID,
          ta.creationDate, 
          ta.lastUpdate 
        FROM 
          taskAssignment ta
        JOIN 
          tasks t ON ta.taskID = t.taskID
        JOIN 
          userProject up ON t.projectID = up.projectID
        WHERE 
          up.userID = ?
      ''', [userID]);
      var remoteAssignments =
          result.map((assignmentMap) => assignmentMap['assignmentID']).toList();
      AppLog.d("Asignaciones remotas: $remoteAssignments");
      // Fetch local assignments
      var localAssignments = await LocalDB.queryTaskAssignments();
      if (localAssignments.isEmpty) {
        AppLog.d("No hay asignaciones locales.");
      } else {
        var localAssignmentIDs =
            localAssignments.map((assignment) => assignment['assignmentID']).toList();

        // Detect deleted assignments
        for (var localAssignmentID in localAssignmentIDs) {
          if (!remoteAssignments.contains(localAssignmentID)) {
            await LocalDB.rawDelete(
              "DELETE FROM taskAssignment WHERE assignmentID = ?",
              [localAssignmentID],
            );
            AppLog.d("Asignación con ID $localAssignmentID marcada como eliminada.");
          }
        }
      }

      for (var assignmentMap in result) {
        var assignmentMapped = TaskAssignment(
          assignmentID: assignmentMap['assignmentID'],
          taskID: assignmentMap['taskID'],
          userID: assignmentMap['userID'],
          creationDate: assignmentMap['creationDate'],
          lastUpdate: assignmentMap['lastUpdate'],
        ).toJson();
        await handleTaskAssignmentSync(assignmentMapped);
      }
      AppLog.d("Asignaciones obtenidas exitosamente.");
    } catch (e) {
      AppLog.e("Error al obtener asignaciones: $e");
    }
  }

  static Future<void> pushTaskAssignments() async {
    if (await ConnectionChecker.checkConnection() == false) {
      AppLog.d("No hay conexión a internet, saltando la sincronización de asignaciones.");
      return;
    }
    try {
      // Mostrar todas las actividades
      var allActivityLog = await LocalDB.query("activityLog");
      AppLog.d("All activities: $allActivityLog");

      var unsyncedAssignments = await LocalDB.queryUnsyncedCreations('taskAssignment');
      AppLog.d("Asignaciones sin sincronizar: ${jsonEncode(unsyncedAssignments)}");

      for (var actMap in unsyncedAssignments) {
        var details = jsonDecode(actMap['activityDetails']);
        var hasDeletion =
            await hasDeletionLog(details['assignmentID'] ?? details['locId']);
        if (!hasDeletion) {
          var creationActivity = await getCreationActivityByAssignmentID(
              details['assignmentID'] ?? details['locId']);
          if (creationActivity != null) {
            if (creationActivity['isSynced'] == 0) {
              await handleRemoteTaskAssignmentInsert(actMap);
            }
          }
        } else {
          await markActivityLogAsSyncedByAssignmentId(
              details['assignmentID'] ?? details['locId']);
        }
      }

      var unsyncedAssignmentUpdates = await LocalDB.queryUnsyncedUpdates('taskAssignment');
      AppLog.d("Asignaciones sin actualizar: ${jsonEncode(unsyncedAssignmentUpdates)}");

      for (var actMap in unsyncedAssignmentUpdates) {
        var details = jsonDecode(actMap['activityDetails']);
        var hasDeletion =
            await hasDeletionLog(actMap['assignmentID'] ?? actMap['locId']);
        if (!hasDeletion) {
          var creationActivity = await getCreationActivityByAssignmentID(
              actMap['assignmentID'] ?? actMap['locId']);
          if (creationActivity != null) {
            if (creationActivity['isSynced'] == 0) {
              await handleRemoteTaskAssignmentUpdate(actMap);
            }
          } else {
            await handleRemoteTaskAssignmentUpdate(actMap);
          }
        } else {
          await markActivityLogAsSyncedByAssignmentId(details['assignmentID']);
        }
      }

      var unsyncedDeletions = await LocalDB.queryUnsyncedDeletions('taskAssignment');
      AppLog.d("Asignaciones sin eliminar: ${jsonEncode(unsyncedDeletions)}");

      for (var deletion in unsyncedDeletions) {
        await handleRemoteTaskAssignmentDeletion(deletion);
      }

      AppLog.d("Asignaciones enviadas exitosamente.");
    } catch (e) {
      AppLog.e("Error al enviar asignaciones: $e");
    }
  }

  //get creation activity by assignmentID
  static Future<Map<String, dynamic>?> getCreationActivityByAssignmentID(
      int assignmentID) async {
    var activities = await LocalDB.rawQuery(
      "SELECT * FROM activityLog WHERE activityType = 'create'",
    );
    for (Map<String, dynamic> activity in activities) {
      var details = jsonDecode(activity['activityDetails']);

      var actAssignmentId = details['locId'];
      if (details['table'] == 'taskAssignment' && actAssignmentId == assignmentID) {
        return activity;
      }
    }
    return null;
  }

  //get update activity by assignmentID
  static Future<Map<String, dynamic>?> getUpdateActivityByAssignmentID(
      int assignmentID) async {
    var activities = await LocalDB.rawQuery(
      "SELECT * FROM activityLog WHERE activityType = 'update'",
    );
    for (Map<String, dynamic> activity in activities) {
      var details = jsonDecode(activity['activityDetails']);

      var actAssignmentId = details['locId'];
      if (details['table'] == 'taskAssignment' && actAssignmentId == assignmentID) {
        return activity;
      }
    }
    return null;
  }

  static Future<void> handleTaskAssignmentSync(Map<String, dynamic> assignmentMap) async {
    var localAssignment = await LocalDB.queryTaskAssignmentByRemoteID(assignmentMap['assignmentID']);
    if (localAssignment == null) {
      await LocalDB.insertTaskAssignment(TaskAssignment.fromJson(assignmentMap));
    } else {
      if (DateTime.parse(assignmentMap['lastUpdate'])
          .isAfter(DateTime.parse(localAssignment['lastUpdate']))) {
        var updated = TaskAssignment.fromJson(assignmentMap);
        updated.locId = localAssignment['locId'];
        await LocalDB.updateTaskAssignment(updated);
      }
    }
  }

  static Future<bool> hasDeletionLog(int assignmentId) async {
    var deletions = await LocalDB.queryUnsyncedDeletions('taskAssignment');
    for (var deletion in deletions) {
      var details = jsonDecode(deletion['activityDetails']);
      if (details['assignmentID'] == assignmentId || details['locId'] == assignmentId) {
        //establecer a la actividad de creacion como isSynced
        var creationActivity = await getCreationActivityByAssignmentID(assignmentId);
        if (creationActivity != null) {
          await LocalDB.markActivityLogAsSynced(creationActivity['locId']);
        }
        return true;
      }
    }
    return false;
  }

  static Future<void> markActivityLogAsSyncedByAssignmentId(int assignmentId) async {
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
      if (data['assignmentID'] == assignmentId || data['locId'] == assignmentId) {
        var updated = await LocalDB.markActivityLogAsSynced(activity['locId']);
        AppLog.d("Actividad de creación marcada como sincronizada: $updated");
      }
    }

    // Marcar actividades de actualización como sincronizadas
    var updates = await LocalDB.queryUnsyncedUpdates('taskAssignment');
    for (var update in updates) {
      var details = jsonDecode(update['activityDetails']);
      if (details['assignmentID'] == assignmentId || details['locId'] == assignmentId) {
        await LocalDB.markActivityLogAsSynced(update['locId']);
      }
    }

    // Marcar actividades de eliminación como sincronizadas
    var deletions = await LocalDB.queryUnsyncedDeletions('taskAssignment');
    for (var deletion in deletions) {
      var details = jsonDecode(deletion['activityDetails']);
      if (details['assignmentID'] == assignmentId || details['locId'] == assignmentId) {
        await LocalDB.markActivityLogAsSynced(deletion['locId']);
      }
    }
  }

  static Future<void> handleRemoteTaskAssignmentInsert(
      Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var assignmentMap = <String, dynamic>{};
    if (actDetails['assignmentID'] != null) {
      assignmentMap = (await LocalDB.queryTaskAssignmentByRemoteID(actDetails['assignmentID']))!;
    } else {
      assignmentMap = (await LocalDB.queryTaskAssignmentByLocalID(actDetails['locId']))!;
    }

    String taskID = assignmentMap['taskID'].toString();
    String userID = assignmentMap['userID'].toString();
    String creationDate = formatDateTime(DateTime.parse(assignmentMap['creationDate']));
    String lastUpdate = formatDateTime(DateTime.parse(assignmentMap['lastUpdate']));

    var response = await DBHelper.query(
      "INSERT INTO taskAssignment (taskID, userID, creationDate, lastUpdate) VALUES (?, ?, ?, ?)",
      [taskID, userID, creationDate, lastUpdate],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);
      var insertId = response.insertId;
      if (insertId != null) {
        await LocalDB.updateTaskAssignmentSyncStatus(assignmentMap['locId'], insertId);
      }
    } else {
      AppLog.e("Error inserting task assignment in remote database: $response");
    }
  }

  static Future<void> handleRemoteTaskAssignmentUpdate(
      Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var assignmentMap = <String, dynamic>{};
    if (actDetails['assignmentID'] != null) {
      assignmentMap = (await LocalDB.queryTaskAssignmentByRemoteID(actDetails['assignmentID']))!;
    } else {
      assignmentMap = (await LocalDB.queryTaskAssignmentByLocalID(actDetails['locId']))!;
    }

    if (assignmentMap.isEmpty) {
      AppLog.e("No se encontró la asignación con ID ${actDetails['assignmentID']}");
      return;
    }

    String taskID = assignmentMap['taskID'].toString();
    String userID = assignmentMap['userID'].toString();
    String creationDate = formatDateTime(DateTime.parse(assignmentMap['creationDate']));
    String lastUpdate = formatDateTime(DateTime.parse(assignmentMap['lastUpdate']));

    //check last update in remote and update only if local is newer
    var remoteAssignment = await DBHelper.query(
      "SELECT * FROM taskAssignment WHERE assignmentID = ?",
      [assignmentMap['assignmentID']],
    );
    if (remoteAssignment.isNotEmpty) {
      var remoteLastUpdate = remoteAssignment.first['lastUpdate'];

      var localLastUpdate = DateTime.parse(assignmentMap['lastUpdate']);
      if (remoteLastUpdate.isAfter(localLastUpdate)) {
        AppLog.d("Asignación remota más reciente, no se actualizará.");
        return;
      }
    }

    var response = await DBHelper.query(
      "UPDATE taskAssignment SET taskID = ?, userID = ?, lastUpdate = ? WHERE assignmentID = ?",
      [
        taskID,
        userID,
        lastUpdate,
        assignmentMap['assignmentID']
      ],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);
    } else {
      AppLog.e("Error updating task assignment in remote database: $response");
    }
  }

  static Future<void> handleRemoteTaskAssignmentDeletion(
      Map<String, dynamic> deletion) async {
    var activityDetails = jsonDecode(deletion['activityDetails']);
    var remoteID = activityDetails['assignmentID'] ?? activityDetails['locId'];
    // Verificar si la asignación existe en la base de datos remota
    var existAssignment = await DBHelper.query(
      "SELECT * FROM taskAssignment WHERE assignmentID = ?",
      [remoteID],
    );
    var assignmentMap = existAssignment.isNotEmpty ? existAssignment.first : null;
    if (assignmentMap != null) {
      await DBHelper.query(
        "DELETE FROM taskAssignment WHERE assignmentID = ?",
        [remoteID],
      );
    }
    var delLocId = deletion['locId'];
    await LocalDB.markActivityLogAsSynced(delLocId);
  }
}
