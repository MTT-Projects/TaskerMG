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
            al.lastUpdate
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

  static Future<void> handleLogSync(Map<String, dynamic> logMap) async {
    var localLog = await LocalDB.queryActivityLogByRemoteID(logMap['activityID']);
    if (localLog == null) {

      await LocalDB.rawQuery(
        "INSERT INTO activityLog (activityID, userID, projectID, activityType, activityDetails, timestamp, lastUpdate, showLog, isSynced) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [
          logMap['activityID'],
          logMap['userID'],
          logMap['projectID'],
          logMap['activityType'],
          logMap['activityDetails']                                                                        ,
          logMap['timestamp'],
          logMap['lastUpdate'],
          1,
          1
        ],
      );
    } 
  }
}
