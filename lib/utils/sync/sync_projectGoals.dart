import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/project.dart';
import 'package:taskermg/utils/AppLog.dart';

class SyncProjectGoals {
  static String formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

  static Future<void> pullProjectGoals(int projectId) async {
    try {
      var result = await DBHelper.query('''
        SELECT 
          goalID, 
          projectID, 
          goalDescription, 
          isCompleted, 
          lastUpdate 
        FROM 
          projectGoal 
        WHERE 
          projectID = ?
      ''', [projectId]);

      var remoteGoals = result.map((goalMap) => goalMap['goalID']).toList();
      var localGoals = await LocalDB.queryProjectGoalsByProjectID(projectId);

      var localGoalIDs = localGoals.map((goal) => goal['goalID']).toList();
      for (var localGoalID in localGoalIDs) {
        if (!remoteGoals.contains(localGoalID)) {
          await LocalDB.rawDelete(
            "DELETE FROM projectGoal WHERE goalID = ?",
            [localGoalID],
          );
          AppLog.d("Goal with ID $localGoalID marked as deleted.");
        }
      }

      for (var goalMap in result) {
        var goalMapped = ProjectGoal(
          goalID: goalMap['goalID'],
          projectID: goalMap['projectID'],
          goalDescription: goalMap['goalDescription'],
          isCompleted: goalMap['isCompleted'] == 1,
          lastUpdate: DateTime.parse(goalMap['lastUpdate']),
        ).toJson();
        await handleGoalSync(goalMapped);
      }

      AppLog.d("Project goals successfully pulled.");
    } catch (e) {
      AppLog.e("Error pulling project goals: $e");
    }
  }

  static Future<void> pushProjectGoals() async {
    try {
      var unsyncedGoals = await LocalDB.queryUnsyncedCreations('projectGoal');
      AppLog.d("Unsynced project goals: ${jsonEncode(unsyncedGoals)}");
      for (var actMap in unsyncedGoals) {
        var details = jsonDecode(actMap['activityDetails']);
        var hasDeletion = await hasDeletionLog(details['goalID'] ?? details['locId']);
        if (!hasDeletion) {
          await handleRemoteGoalInsert(actMap);
        } else {
          await markActivityLogAsSyncedByGoalId(details['goalID']);
        }
      }

      var unsyncedGoalUpdates = await LocalDB.queryUnsyncedUpdates('projectGoal');
      AppLog.d("Unsynced project goal updates: ${jsonEncode(unsyncedGoalUpdates)}");
      for (var actMap in unsyncedGoalUpdates) {
        var details = jsonDecode(actMap['activityDetails']);
        var hasDeletion = await hasDeletionLog(details['goalID'] ?? details['locId']);
        if (!hasDeletion) {
          var creationActivity = await getCreationActivityByGoalID(details['goalID'] ?? details['locId']);
          if (creationActivity != null) {
            if (creationActivity['isSynced'] == 0) {
              await handleRemoteGoalUpdate(actMap);
            }
          } else {
            await handleRemoteGoalUpdate(actMap);
          }
        } else {
          await markActivityLogAsSyncedByGoalId(details['goalID']);
        }
      }

      var unsyncedDeletions = await LocalDB.queryUnsyncedDeletions('projectGoal');
      AppLog.d("Unsynced project goal deletions: ${jsonEncode(unsyncedDeletions)}");
      for (var deletion in unsyncedDeletions) {
        await handleRemoteGoalDeletion(deletion);
      }

      AppLog.d("Project goals successfully pushed.");
    } catch (e) {
      AppLog.e("Error pushing project goals: $e");
    }
  }

  static Future<Map<String, dynamic>?> getCreationActivityByGoalID(int goalID) async {
    var activities = await LocalDB.rawQuery(
      "SELECT * FROM activityLog WHERE activityType = 'create'",
    );
    for (Map<String, dynamic> activity in activities) {
      var details = jsonDecode(activity['activityDetails']);
      var actGoalId = details['locId'];
      if (details['table'] == 'projectGoal' && actGoalId == goalID) {
        return activity;
      }
    }
    return null;
  }

  static Future<void> handleGoalSync(Map<String, dynamic> goalMap) async {
    var localGoal = await LocalDB.queryProjectGoalByRemoteID(goalMap['goalID']);
    if (localGoal == null) {
      AppLog.d("Local goal not found, creating a new one");
      await LocalDB.insertProjectGoal(ProjectGoal.fromJson(goalMap));
    } else {
      goalMap['locId'] = localGoal['locId'];
      if (DateTime.parse(goalMap['lastUpdate']).isAfter(DateTime.parse(localGoal['lastUpdate']))) {
        await LocalDB.updateProjectGoal(ProjectGoal.fromJson(goalMap));
      }
    }
  }

  static Future<void> handleRemoteGoalInsert(Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var goalMap = <String, dynamic>{};
    if (actDetails['goalID'] != null) {
      goalMap = (await LocalDB.queryProjectByRemoteID(actDetails['goalID']))!;
    } else {
      goalMap = (await LocalDB.queryProjectGoalByLocalID(actDetails['locId']))!;
    }

    String goalDescription = goalMap['goalDescription'];
    int isCompleted = goalMap['isCompleted'] ? 1 : 0;
    String lastUpdate = formatDateTime(DateTime.parse(goalMap['lastUpdate']));

    var response = await DBHelper.query(
      "INSERT INTO projectGoal (projectID, goalDescription, isCompleted, lastUpdate) VALUES (?, ?, ?, ?)",
      [goalMap['projectID'], goalDescription, isCompleted, lastUpdate],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);
      var insertId = response.insertId;
      if (insertId != null) {
        await LocalDB.updateProjectGoalSyncStatus(goalMap['locId'], insertId);
      }
    } else {
      AppLog.e("Error inserting project goal in remote database: $response");
    }
  }

  static Future<void> handleRemoteGoalUpdate(Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var goalMap = <String, dynamic>{};
    if (actDetails['goalID'] != null) {
      goalMap = (await LocalDB.queryProjectGoalByRemoteID(actDetails['goalID']))!;
    } else {
      goalMap = (await LocalDB.queryProjectGoalByLocalID(actDetails['locId']))!;
    }

    String goalDescription = goalMap['goalDescription'];
    int isCompleted = goalMap['isCompleted'] ? 1 : 0;
    String lastUpdate = formatDateTime(DateTime.parse(goalMap['lastUpdate']));

    var remoteGoal = await DBHelper.query(
      "SELECT * FROM projectGoal WHERE goalID = ?",
      [goalMap['goalID']],
    );
    if (remoteGoal.isNotEmpty) {
      var remoteLastUpdate = DateTime.parse(remoteGoal.first['lastUpdate']);
      var localLastUpdate = DateTime.parse(goalMap['lastUpdate']);
      if (remoteLastUpdate.isAfter(localLastUpdate)) {
        AppLog.d("Remote goal is more recent, not updating.");
        return;
      }
    }

    var response = await DBHelper.query(
      "UPDATE projectGoal SET goalDescription = ?, isCompleted = ?, lastUpdate = ? WHERE goalID = ?",
      [goalDescription, isCompleted, lastUpdate, goalMap['goalID']],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);
    } else {
      AppLog.e("Error updating project goal in remote database: $response");
    }
  }

  static Future<void> handleRemoteGoalDeletion(Map<String, dynamic> deletion) async {
    var activityDetails = jsonDecode(deletion['activityDetails']);
    var remoteID = activityDetails['goalID'] ?? activityDetails['locId'];
    var existGoal = await DBHelper.query(
      "SELECT * FROM projectGoal WHERE goalID = ?",
      [remoteID],
    );
    var goalMap = existGoal.isNotEmpty ? existGoal.first : null;
    if (goalMap != null) {
      await DBHelper.query(
        "DELETE FROM projectGoal WHERE goalID = ?",
        [remoteID],
      );
    }
    var delLocId = deletion['locId'];
    await LocalDB.markActivityLogAsSynced(delLocId);
  }

  static Future<bool> hasDeletionLog(int goalID) async {
    var deletions = await LocalDB.queryUnsyncedDeletions('projectGoal');
    for (var deletion in deletions) {
      var details = jsonDecode(deletion['activityDetails']);
      if (details['goalID'] == goalID || details['locId'] == goalID) {
        var creationActivity = await getCreationActivityByGoalID(goalID);
        if (creationActivity != null) {
          await LocalDB.markActivityLogAsSynced(creationActivity['locId']);
        }
        return true;
      }
    }
    return false;
  }

  static Future<void> markActivityLogAsSyncedByGoalId(int goalID) async {
    var activities = await LocalDB.queryUnsyncedActivityLogs();
    var filAct = [];
    for (var act in activities) {
      if (act['activityType'] == 'create' || act['activityType'] == 'update') {
        filAct.add(act);
      }
    }

    for (var activity in filAct) {
      var data = jsonDecode(activity['activityDetails']);
      if (data['goalID'] == goalID || data['locId'] == goalID) {
        var updated = await LocalDB.markActivityLogAsSynced(activity['locId']);
        AppLog.d("Creation activity marked as synced: $updated");
      }
    }

    var updates = await LocalDB.queryUnsyncedUpdates('projectGoal');
    for (var update in updates) {
      var details = jsonDecode(update['activityDetails']);
      if (details['goalID'] == goalID || details['locId'] == goalID) {
        await LocalDB.markActivityLogAsSynced(update['locId']);
      }
    }

    var deletions = await LocalDB.queryUnsyncedDeletions('projectGoal');
    for (var deletion in deletions) {
      var details = jsonDecode(deletion['activityDetails']);
      if (details['goalID'] == goalID || details['locId'] == goalID) {
        await LocalDB.markActivityLogAsSynced(deletion['locId']);
      }
    }
  }
}
