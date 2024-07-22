import 'package:get/get.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/activity_log.dart';
import 'package:taskermg/models/user.dart';
import 'package:taskermg/controllers/user_controller.dart';

class LogActivityController extends GetxController {
  var activityLogs = <ActivityLog>[].obs;

  Future<void> fetchActivityLogs(int projectID) async {
    activityLogs.clear();
    List<Map<String, dynamic>> logsData = await LocalDB.rawQuery(
      "SELECT * FROM activityLog WHERE showLog = 1 AND activityType = 'update' AND projectID = ? ORDER BY timestamp DESC",
      [projectID]
    );

    List<ActivityLog> logs = logsData.map((data) => ActivityLog.fromJson(data)).toList();
    activityLogs.assignAll(logs);
  }

  Future<Map<String, dynamic>?> getUserDataById(int userID) async {
    final userName = await UserController.getUserName(userID);
    final profileData = await UserController.getProfileData(userID);

    if (userName.isNotEmpty && profileData != null) {
      return {
        'name': userName,
        'profilePicUrl': profileData['profilePicUrl'],
      };
    }

    return null;
  }

  Future<String?> getTaskNameById(int? taskId) async {
    if (taskId == null) {
      return null;
    }

    var taskData = await LocalDB.rawQuery(
      'SELECT title FROM tasks WHERE taskID = ?',
      [taskId],
    );

    if (taskData.isNotEmpty) {
      return taskData.first['title'];
    }

    return null;
  }
}
