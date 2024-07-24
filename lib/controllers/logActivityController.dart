import 'package:get/get.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/activity_log.dart';
import 'package:taskermg/controllers/user_controller.dart';

class LogActivityController extends GetxController {
  var activityLogs = <ActivityLog>[].obs;
  var userDataCache = <int, Map<String, dynamic>>{}.obs;
  var taskNameCache = <int, String>{}.obs;
  var isLoading = false.obs;

  Future<void> fetchActivityLogs(int projectID) async {
    isLoading(true); // Start loading
    activityLogs.clear();
    List<Map<String, dynamic>> logsData = await LocalDB.rawQuery(
      "SELECT * FROM activityLog WHERE showLog = 1 AND activityType = 'update' AND projectID = ? ORDER BY timestamp DESC",
      [projectID]
    );

    List<ActivityLog> logs = logsData.map((data) => ActivityLog.fromJson(data)).toList();
    activityLogs.assignAll(logs);

    // Cargar datos de usuario y nombres de tareas una sola vez
    await _loadUserDataAndTaskNames(logs);
    isLoading(false); // Stop loading
  }

  Future<void> _loadUserDataAndTaskNames(List<ActivityLog> logs) async {
    for (var log in logs) {
      if (!userDataCache.containsKey(log.userID)) {
        final userName = await UserController.getUserName(log.userID!);
        final profileData = await UserController.getProfileData(log.userID!);

        if (userName.isNotEmpty && profileData != null) {
          userDataCache[log.userID!] = {
            'name': userName,
            'profilePicUrl': profileData['profilePicUrl'],
          };
        } else {
          userDataCache[log.userID!] = {
            'name': 'User',
            'profilePicUrl': null,
          };
        }
      }

      final taskId = log.activityDetails?['taskID'];
      if (taskId != null && !taskNameCache.containsKey(taskId)) {
        var taskData = await LocalDB.rawQuery(
          'SELECT title FROM tasks WHERE taskID = ?',
          [taskId],
        );

        if (taskData.isNotEmpty) {
          taskNameCache[taskId] = taskData.first['title'];
        } else {
          taskNameCache[taskId] = 'desconocida';
        }
      }
    }
  }

  Map<String, dynamic>? getUserData(int userID) {
    return userDataCache[userID];
  }

  String? getTaskName(int? taskId) {
    if (taskId == null) {
      return null;
    }
    return taskNameCache[taskId];
  }
}
