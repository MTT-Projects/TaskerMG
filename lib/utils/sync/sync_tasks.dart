import 'dart:convert';
import 'package:mysql1/mysql1.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/task_controller.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/task.dart';
import 'package:taskermg/utils/AppLog.dart';
import 'package:intl/intl.dart';

class SyncTasks {
  static TaskController tkController = TaskController();

  static String formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

  static Future<void> pullTasks() async {
    var userID = MainController.getVar('currentUser');
    try {
      var result = await DBHelper.query('''SELECT 
          t.taskID, 
          t.projectID, 
          t.title, 
          t.description, 
          t.deadline, 
          t.priority, 
          t.status, 
          t.creationDate, 
          t.lastUpdate,
          t.createdUserID
        FROM 
          tasks t
        JOIN 
          project p ON t.projectID = p.projectID
        JOIN 
          userProject up ON p.projectID = up.projectID
        JOIN 
          user u ON up.userID = u.userID
        WHERE 
          u.userID = ?''', [userID]);
      for (var taskMap in result) {
        var taskMapped = Task(
          taskID: taskMap['taskID'],
          projectID: taskMap['projectID'],
          title: taskMap['title'],
          description: taskMap['description'].toString(),
          deadline: taskMap['deadline'],
          priority: taskMap['priority'],
          status: taskMap['status'],
          creationDate: taskMap['creationDate'],
          createdUserID: taskMap['createdUserID'],
          lastUpdate: taskMap['lastUpdate'],
        ).toJson();
        await handleTaskSync(taskMapped);
      }
      AppLog.d("Tareas obtenidas exitosamente.");
    } catch (e) {
      AppLog.e("Error al obtener tareas: $e");
    }
  }

  static Future<void> pushTasks() async {
    try {
      var unsyncedTasks = await LocalDB.queryUnsyncedTasks();
      AppLog.d("Tareas sin sincronizar: ${jsonEncode(unsyncedTasks)}");
      for (var taskMap in unsyncedTasks) {
        await handleRemoteTaskInsert(taskMap);
      }

      var unsyncedTaskUpdates = await LocalDB.queryUnsyncedUpdates('tasks');
      AppLog.d("Tareas sin actualizar: ${jsonEncode(unsyncedTaskUpdates)}");
      for (var actMap in unsyncedTaskUpdates) {
        await handleRemoteTaskUpdate(actMap);
      }

      var unsyncedDeletions = await LocalDB.queryUnsyncedDeletions('tasks');
      AppLog.d("Tareas sin eliminar: ${jsonEncode(unsyncedDeletions)}");
      for (var deletion in unsyncedDeletions) {
        await handleRemoteTaskDeletion(deletion);
      }

      AppLog.d("Tareas enviadas exitosamente.");
    } catch (e) {
      AppLog.e("Error al enviar tareas: $e");
    }
  }

  static Future<void> handleTaskSync(Map<String, dynamic> taskMap) async {
    var localTask = await LocalDB.queryTaskByRemoteID(taskMap['taskID']);
    if (localTask == null) {
      await LocalDB.insertTask(Task.fromJson(taskMap));
    } else {
      if (DateTime.parse(taskMap['lastUpdate']).isAfter(DateTime.parse(localTask['lastUpdate']))) {
        await tkController.updateTask(Task.fromJson(taskMap));
      }
    }
  }

  static Future<void> handleRemoteTaskInsert(Map<String, dynamic> taskMap) async {
    String projectID = taskMap['projectID'].toString();
    String title = taskMap['title'];
    String description = taskMap['description'];
    String deadline = formatDateTime(DateTime.parse(taskMap['deadline']));
    String priority = taskMap['priority'];
    String status = taskMap['status'];
    String creationDate = formatDateTime(DateTime.parse(taskMap['creationDate']));
    String lastUpdate = formatDateTime(DateTime.parse(taskMap['lastUpdate']));
    String createdUserID = taskMap['createdUserID'].toString();

    var response = await DBHelper.query(
      "INSERT INTO tasks (projectID, title, description, deadline, priority, status, creationDate, lastUpdate, createdUserID) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
      [projectID, title, description, deadline, priority, status, creationDate, lastUpdate, createdUserID],
    );

    if (response is Results) {
      var insertId = response.insertId;
      if (insertId != null) {
        await LocalDB.updateTaskSyncStatus(taskMap['locId'], insertId);
      }
    } else {
      AppLog.e("Error inserting task in remote database: $response");
    }
  }

  static Future<void> handleRemoteTaskUpdate(Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var taskMap = Map<String, dynamic>();
    if (actDetails['taskID'] != null) {
      taskMap = (await LocalDB.queryTaskByRemoteID(actDetails['taskID']))!;
    } else {
      taskMap = (await LocalDB.queryTaskByLocalID(actDetails['locId']))!;
    }

    String projectID = taskMap['projectID'].toString();
    String title = taskMap['title'];
    String description = taskMap['description'];
    String deadline = formatDateTime(DateTime.parse(taskMap['deadline']));
    String priority = taskMap['priority'];
    String status = taskMap['status'];
    String creationDate = formatDateTime(DateTime.parse(taskMap['creationDate']));
    String lastUpdate = formatDateTime(DateTime.parse(taskMap['lastUpdate']));
    String createdUserID = taskMap['createdUserID'].toString();

    var response = await DBHelper.query(
      "UPDATE tasks SET projectID = ?, title = ?, description = ?, deadline = ?, priority = ?, status = ?, lastUpdate = ? WHERE taskID = ?",
      [projectID, title, description, deadline, priority, status, lastUpdate, taskMap['taskID']],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);
    } else {
      AppLog.e("Error updating task in remote database: $response");
    }
  }

  static Future<void> handleRemoteTaskDeletion(Map<String, dynamic> deletion) async {
    var activityDetails = jsonDecode(deletion['activityDetails']);
    var remoteID = activityDetails['taskID'] ?? activityDetails['locId'];
    await DBHelper.query(
      "DELETE FROM tasks WHERE taskID = ?",
      [remoteID],
    );
    var delLocId = deletion['locId'];
    await LocalDB.markActivityLogAsSynced(delLocId);
  }
}
