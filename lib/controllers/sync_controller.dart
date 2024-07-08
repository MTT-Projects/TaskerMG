import 'package:get/get.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/models/task.dart';
import 'package:taskermg/models/project.dart';
import 'package:taskermg/models/activity_log.dart';

class SyncController extends GetxController {
  Future<void> syncData() async {
    await _syncActivityLogs();
  }

  Future<void> _syncActivityLogs() async {
    List<Map<String, dynamic>> unsyncedActivityLogs = await LocalDB.queryUnsyncedActivityLogs();
    for (var activityLogMap in unsyncedActivityLogs) {
      ActivityLog activityLog = ActivityLog.fromJson(activityLogMap);

      try {
        if (activityLog.activityType == 'create') {
          int remoteId;
          if (activityLog.activityDetails!['table'] == 'projects') {
            Project project = await LocalDB.db.query("projects", where: 'loc_id = ?', whereArgs: [activityLog.activityDetails!['loc_id']]).then((value) => Project.fromJson(value.first));
            var query = 'INSERT INTO projects (name, description, deadline) VALUES (?, ?, ?)';
            remoteId = await DBHelper.query(query, [project.name, project.description, project.deadline?.toIso8601String()]);
            await LocalDB.updateProjectSyncStatus(project.locId!, remoteId);
          } else if (activityLog.activityDetails!['table'] == 'tasks') {
            Task task = await LocalDB.db.query("tasks", where: 'loc_id = ?', whereArgs: [activityLog.activityDetails!['loc_id']]).then((value) => Task.fromJson(value.first));
            var query = 'INSERT INTO tasks (title, description, status, deadline) VALUES (?, ?, ?, ?)';
            remoteId = await DBHelper.query(query, [task.title, task.description, task.status, task.deadline?.toIso8601String()]);
            await LocalDB.updateTaskSyncStatus(task.locId!, remoteId);
          }
          await LocalDB.updateActivityLogSyncStatus(activityLog.activityID!, true);
        } else if (activityLog.activityType == 'update') {
          if (activityLog.activityDetails!['table'] == 'projects') {
            Project project = await LocalDB.db.query("projects", where: 'loc_id = ?', whereArgs: [activityLog.activityDetails!['loc_id']]).then((value) => Project.fromJson(value.first));
            await DBHelper.query(
              'UPDATE projects SET name = ?, description = ?, deadline = ? WHERE id = ?',
              [project.name, project.description, project.deadline?.toIso8601String(), project.projectID]
            );
          } else if (activityLog.activityDetails!['table'] == 'tasks') {
            Task task = await LocalDB.db.query("tasks", where: 'loc_id = ?', whereArgs: [activityLog.activityDetails!['loc_id']]).then((value) => Task.fromJson(value.first));
            await DBHelper.query(
              'UPDATE tasks SET title = ?, description = ?, status = ?, deadline = ? WHERE id = ?',
              [task.title, task.description, task.status, task.deadline?.toIso8601String(), task.taskID]
            );
          }
          await LocalDB.updateActivityLogSyncStatus(activityLog.activityID!, true);
        } else if (activityLog.activityType == 'delete') {
          await DBHelper.query(
            'DELETE FROM ${activityLog.activityDetails!['table']} WHERE id = ?',
            [activityLog.activityDetails!['id']]
          );
          await LocalDB.updateActivityLogSyncStatus(activityLog.activityID!, true);
        }
      } catch (e) {
        // Handle error
      }
    }
  }
}
