import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/activity_log.dart';
import 'package:taskermg/utils/AppLog.dart';

class SyncActivityLogs {
  static String formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

  static Future<void> pullActivityLogs() async {
    var userID = MainController.getVar('currentUser');
    try {
      var result = await DBHelper.query('''
        SELECT 
            al.activityID, 
            al.userID, 
            al.projectID, 
            al.activityType, 
            al.activityDetails, 
            al.timestamp, 
            al.lastUpdate,
        FROM 
            activityLog al
        JOIN 
            project p ON al.projectID = p.projectID
        JOIN 
            userProject up ON p.projectID = up.projectID
        WHERE 
            up.userID = ?
      ''', [userID]);

      var remoteActivityLogs = result.map((logMap) => logMap['activityID']).toList();
      AppLog.d("Activity Logs remotos: $remoteActivityLogs");

      // Fetch local activity logs
      var localActivityLogs = await LocalDB.query('activityLog');
      if (localActivityLogs.isEmpty) {
        AppLog.d("No hay logs de actividad locales.");
      } else {
        var localActivityLogIDs = localActivityLogs.map((log) => log['activityID']).toList();

        // Detect deleted logs
        for (var localActivityLogID in localActivityLogIDs) {
          if (!remoteActivityLogs.contains(localActivityLogID)) {
            await LocalDB.rawDelete(
              "DELETE FROM activityLog WHERE activityID = ?",
              [localActivityLogID],
            );
            AppLog.d("Log de actividad con ID $localActivityLogID marcado como eliminado.");
          }
        }
      }

      for (var logMap in result) {
        var logMapped = ActivityLog(
          activityID: logMap['activityID'],
          userID: logMap['userID'],
          projectID: logMap['projectID'],
          activityType: logMap['activityType'],
          activityDetails: jsonDecode(logMap['activityDetails']),
          timestamp: logMap['timestamp'],
          lastUpdate: logMap['lastUpdate'],
        ).toJson();
        await handleLogSync(logMapped);
      }
      AppLog.d("Logs de actividad obtenidos exitosamente.");
    } catch (e) {
      AppLog.e("Error al obtener logs de actividad: $e");
    }
  }

  static Future<void> pushActivityLogs() async {
    try {
      var unsyncedLogs = await LocalDB.queryUnsyncedCreations('activityLog');
      AppLog.d("Logs de actividad sin sincronizar: ${jsonEncode(unsyncedLogs)}");

      for (var actMap in unsyncedLogs) {
        var details = jsonDecode(actMap['activityDetails']);
        var hasDeletion = await hasDeletionLog(details['activityID'] ?? details['locId']);
        if (!hasDeletion) {
          var creationActivity = await getCreationActivityByLogID(details['activityID'] ?? details['locId']);
          if (creationActivity != null) {
            if (creationActivity['isSynced'] == 0) {
              await handleRemoteLogInsert(actMap);
            }
          }
        } else {
          await markActivityLogAsSyncedByLogId(details['activityID'] ?? details['locId']);
        }
      }

      var unsyncedDeletions = await LocalDB.queryUnsyncedDeletions('activityLog');
      AppLog.d("Logs de actividad sin eliminar: ${jsonEncode(unsyncedDeletions)}");

      for (var deletion in unsyncedDeletions) {
        await handleRemoteLogDeletion(deletion);
      }

      AppLog.d("Logs de actividad enviados exitosamente.");
    } catch (e) {
      AppLog.e("Error al enviar logs de actividad: $e");
    }
  }

  static Future<Map<String, dynamic>?> getCreationActivityByLogID(int activityLogID) async {
    var activities = await LocalDB.rawQuery(
      "SELECT * FROM activityLog WHERE activityType = 'create'",
    );
    for (Map<String, dynamic> activity in activities) {
      var details = jsonDecode(activity['activityDetails']);

      var actLogId = details['locId'];
      if (details['table'] == 'activityLog' && actLogId == activityLogID) {
        return activity;
      }
    }
    return null;
  }

  static Future<void> handleLogSync(Map<String, dynamic> logMap) async {
    var localLog = await LocalDB.queryActivityLogByRemoteID(logMap['activityID']);
    if (localLog == null) {
      await LocalDB.insertActivityLog(ActivityLog.fromJson(logMap));
    } else {
      if (DateTime.parse(logMap['lastUpdate']).isAfter(DateTime.parse(localLog['lastUpdate']))) {
        var updated = ActivityLog.fromJson(logMap);
        updated.locId = localLog['locId'];
        await LocalDB.updateActivityLog(updated);
      }
    }
  }

  static Future<bool> hasDeletionLog(int activityLogId) async {
    var deletions = await LocalDB.queryUnsyncedDeletions('activityLog');
    for (var deletion in deletions) {
      var details = jsonDecode(deletion['activityDetails']);
      if (details['activityID'] == activityLogId || details['locId'] == activityLogId) {
        var creationActivity = await getCreationActivityByLogID(activityLogId);
        if (creationActivity != null) {
          await LocalDB.markActivityLogAsSynced(creationActivity['locId']);
        }
        return true;
      }
    }
    return false;
  }

  static Future<void> markActivityLogAsSyncedByLogId(int activityLogId) async {
    var activities = await LocalDB.queryUnsyncedActivityLogs();
    var filAct = [];
    for (var act in activities) {
      if (act['activityType'] == 'create') {
        filAct.add(act);
      }
    }

    for (var activity in filAct) {
      var data = jsonDecode(activity['activityDetails']);
      if (data['activityID'] == activityLogId || data['locId'] == activityLogId) {
        var updated = await LocalDB.markActivityLogAsSynced(activity['locId']);
        AppLog.d("Actividad de creación marcada como sincronizada: $updated");
      }
    }

    var deletions = await LocalDB.queryUnsyncedDeletions('activityLog');
    for (var deletion in deletions) {
      var details = jsonDecode(deletion['activityDetails']);
      if (details['activityID'] == activityLogId || details['locId'] == activityLogId) {
        await LocalDB.markActivityLogAsSynced(deletion['locId']);
      }
    }
  }

  static Future<void> handleRemoteLogInsert(Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var logMap = <String, dynamic>{};
    if (actDetails['activityID'] != null) {
      logMap = (await LocalDB.queryActivityLogByRemoteID(actDetails['activityID']))!;
    } else {
      logMap = (await LocalDB.queryActivityLogByLocalID(actDetails['locId']))!;
    }

    String userID = logMap['userID'].toString();
    String projectID = logMap['projectID'].toString();
    String activityType = logMap['activityType'];
    String activityDetails = jsonEncode(logMap['activityDetails']);
    String timestamp = formatDateTime(DateTime.parse(logMap['timestamp']));
    String lastUpdate = formatDateTime(DateTime.parse(logMap['lastUpdate']));

    var response = await DBHelper.query(
      "INSERT INTO activityLog (userID, projectID, activityType, activityDetails, timestamp, lastUpdate) VALUES (?, ?, ?, ?, ?, ?)",
      [userID, projectID, activityType, activityDetails, timestamp, lastUpdate],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);
      var insertId = response.insertId;
      if (insertId != null) {
        await LocalDB.updateActivityLogSyncStatus(logMap['locId'], insertId);
      }
    } else {
      AppLog.e("Error inserting activityLog in remote database: $response");
    }
  }

  static Future<void> handleRemoteLogDeletion(Map<String, dynamic> deletion) async {
    var activityDetails = jsonDecode(deletion['activityDetails']);
    var remoteID = activityDetails['activityID'] ?? activityDetails['locId'];
    var existLog = await DBHelper.query(
      "SELECT * FROM activityLog WHERE activityID = ?",
      [remoteID],
    );
    var logMap = existLog.isNotEmpty ? existLog.first : null;
    if (logMap != null) {
      await DBHelper.query(
        "DELETE FROM activityLog WHERE activityID = ?",
        [remoteID],
      );
    }
    var delLocId = deletion['locId'];
    await LocalDB.markActivityLogAsSynced(delLocId);
  }
}
