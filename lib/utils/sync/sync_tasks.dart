import 'dart:convert';
import 'package:googleapis/admob/v1.dart';
import 'package:mysql1/mysql1.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/task_controller.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/task.dart';
import 'package:taskermg/utils/AppLog.dart';
import 'package:intl/intl.dart';

class SyncTasks {
  static String formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

  static Future<void> pullTasks() async {
    var userID = MainController.getVar('currentUser');
    try {
      var result = await DBHelper.query('''
        SELECT 
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
        WHERE 
          up.userID = ?
      ''', [userID]);
      var remoteTasks =
          result.map((projectMap) => projectMap['taskID']).toList();
      AppLog.d("Tareas remotas: $remoteTasks");
      // Fetch local tasks
      var localTasks = await LocalDB.queryTasks();
      if (localTasks.isEmpty) {
        AppLog.d("No hay tareas locales.");
      } else {
        var localTaskIDs =
            localTasks.map((project) => project['taskID']).toList();

        // Detect deleted tasks
        for (var localTaskID in localTaskIDs) {
          if (!remoteTasks.contains(localTaskID)) {
            await LocalDB.rawDelete(
              "DELETE FROM tasks WHERE taskID = ?",
              [localTaskID],
            );
            AppLog.d("Tarea con ID $localTaskID marcada como eliminada.");
          }
        }
      }

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
      // Mostrar todas las actividades
      var allActivityLog = await LocalDB.query("activityLog");
      AppLog.d("All activities: $allActivityLog");

      var unsyncedTasks = await LocalDB.queryUnsyncedCreations('tasks');
      AppLog.d("Tareas sin sincronizar: ${jsonEncode(unsyncedTasks)}");

      for (var actMap in unsyncedTasks) {
        var details = jsonDecode(actMap['activityDetails']);
        var hasDeletion =
            await hasDeletionLog(details['taskID'] ?? details['locId']);
        if (!hasDeletion) {
          var creationActivity = await getCreationActivityByTaskID(
              details['taskID'] ?? details['locId']);
          if (creationActivity != null) {
            if (creationActivity['isSynced'] == 0) {
              await handleRemoteTaskInsert(actMap);
            }
          }
        } else {
          await markActivityLogAsSyncedByTaskId(
              details['taskID'] ?? details['locId']);
        }
      }

      var unsyncedTaskUpdates = await LocalDB.queryUnsyncedUpdates('tasks');
      AppLog.d("Tareas sin actualizar: ${jsonEncode(unsyncedTaskUpdates)}");

      for (var actMap in unsyncedTaskUpdates) {
        var details = jsonDecode(actMap['activityDetails']);
        var hasDeletion =
            await hasDeletionLog(actMap['taskID'] ?? actMap['locId']);
        if (!hasDeletion) {
          var creationActivity = await getCreationActivityByTaskID(
              actMap['taskID'] ?? actMap['locId']);
          if (creationActivity != null) {
            if (creationActivity['isSynced'] == 1) {
              await handleRemoteTaskUpdate(actMap);
            }
          } else {
            await handleRemoteTaskUpdate(actMap);
          }
        } else {
          await markActivityLogAsSyncedByTaskId(details['taskID']);
        }
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

  //get creation activity by taskID
  static Future<Map<String, dynamic>?> getCreationActivityByTaskID(
      int taskID) async {
    var activities = await LocalDB.rawQuery(
      "SELECT * FROM activityLog WHERE activityType = 'create'",
    );
    for (Map<String, dynamic> activity in activities) {
      var details = jsonDecode(activity['activityDetails']);

      var actTaskId = details['locId'];
      if (details['table'] == 'tasks' && actTaskId == taskID) {
        return activity;
      }
    }
    return null;
  }

  //get update activity by taskID
  static Future<Map<String, dynamic>?> getUpdateActivityByTaskID(
      int taskID) async {
    var activities = await LocalDB.rawQuery(
      "SELECT * FROM activityLog WHERE activityType = 'update'",
    );
    for (Map<String, dynamic> activity in activities) {
      var details = jsonDecode(activity['activityDetails']);

      var actTaskId = details['locId'];
      if (details['table'] == 'tasks' && actTaskId == taskID) {
        return activity;
      }
    }
    return null;
  }

  static Future<void> handleTaskSync(Map<String, dynamic> taskMap) async {
    var localTask = await LocalDB.queryTaskByRemoteID(taskMap['taskID']);
    if (localTask == null) {
      await LocalDB.insertTask(Task.fromJson(taskMap));
    } else {
      if (DateTime.parse(taskMap['lastUpdate'])
          .isAfter(DateTime.parse(localTask['lastUpdate']))) {
        AppLog.d("Tarea ${localTask} local más antigua, actualizando...");
        var updated = Task.fromJson(taskMap);
        updated.locId = localTask['locId'];
        AppLog.d("Tarea ${localTask} actualizada con $updated");
        await LocalDB.updateTask(updated);
      }
    }
  }

  static Future<bool> hasDeletionLog(int taskId) async {
    var deletions = await LocalDB.queryUnsyncedDeletions('tasks');
    for (var deletion in deletions) {
      var details = jsonDecode(deletion['activityDetails']);
      if (details['taskID'] == taskId || details['locId'] == taskId) {
        //establecer a la actividad de creacion como isSynced
        var creationActivity = await getCreationActivityByTaskID(taskId);
        if (creationActivity != null) {
          await LocalDB.markActivityLogAsSynced(creationActivity['locId']);
        }
        return true;
      }
    }
    return false;
  }

  static Future<void> markActivityLogAsSyncedByTaskId(int taskId) async {
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
      if (data['taskID'] == taskId || data['locId'] == taskId) {
        var updated = await LocalDB.markActivityLogAsSynced(activity['locId']);
        AppLog.d("Actividad de creación marcada como sincronizada: $updated");
      }
    }

    // Marcar actividades de actualización como sincronizadas
    var updates = await LocalDB.queryUnsyncedUpdates('tasks');
    for (var update in updates) {
      var details = jsonDecode(update['activityDetails']);
      if (details['taskID'] == taskId || details['locId'] == taskId) {
        await LocalDB.markActivityLogAsSynced(update['locId']);
      }
    }

    // Marcar actividades de eliminación como sincronizadas
    var deletions = await LocalDB.queryUnsyncedDeletions('tasks');
    for (var deletion in deletions) {
      var details = jsonDecode(deletion['activityDetails']);
      if (details['taskID'] == taskId || details['locId'] == taskId) {
        await LocalDB.markActivityLogAsSynced(deletion['locId']);
      }
    }
  }

  static Future<void> handleRemoteTaskInsert(
      Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var taskMap = <String, dynamic>{};
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
    String creationDate =
        formatDateTime(DateTime.parse(taskMap['creationDate']));
    String lastUpdate = formatDateTime(DateTime.parse(taskMap['lastUpdate']));
    String createdUserID = taskMap['createdUserID'].toString();

    var response = await DBHelper.query(
      "INSERT INTO tasks (projectID, title, description, deadline, priority, status, creationDate, lastUpdate, createdUserID) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
      [
        projectID,
        title,
        description,
        deadline,
        priority,
        status,
        creationDate,
        lastUpdate,
        createdUserID
      ],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);
      var insertId = response.insertId;
      if (insertId != null) {
        await LocalDB.updateTaskSyncStatus(taskMap['locId'], insertId);
      }
    } else {
      AppLog.e("Error inserting task in remote database: $response");
    }
  }

  static Future<void> handleRemoteTaskUpdate(
      Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var taskMap = <String, dynamic>{};
    if (actDetails['taskID'] != null) {
      taskMap = (await LocalDB.queryTaskByRemoteID(actDetails['taskID']))!;
    } else {
      taskMap = (await LocalDB.queryTaskByLocalID(actDetails['locId']))!;
    }

    if (taskMap.isEmpty) {
      AppLog.e("No se encontró la tarea con ID ${actDetails['taskID']}");
      return;
    }

    String projectID = taskMap['projectID'].toString();
    String title = taskMap['title'];
    String description = taskMap['description'];
    String deadline = formatDateTime(DateTime.parse(taskMap['deadline']));
    String priority = taskMap['priority'];
    String status = taskMap['status'];
    String creationDate =
        formatDateTime(DateTime.parse(taskMap['creationDate']));
    String lastUpdate = formatDateTime(DateTime.parse(taskMap['lastUpdate']));
    String createdUserID = taskMap['createdUserID'].toString();

    //check last update in remote and update only if local is newer
    var remoteTask = await DBHelper.query(
      "SELECT * FROM tasks WHERE taskID = ?",
      [taskMap['taskID']],
    );

    if (remoteTask.isNotEmpty) {
      var remoteLastUpdate = remoteTask.first['lastUpdate'];

      var localLastUpdate = DateTime.parse(taskMap['lastUpdate']);
      if (remoteLastUpdate.isAfter(localLastUpdate)) {
        AppLog.d("Tarea remota más reciente, no se actualizará.");
        return;
      }
    }

    var response = await DBHelper.query(
      "UPDATE tasks SET title = ?, description = ?, deadline = ?, priority = ?, status = ?, lastUpdate = ? WHERE taskID = ?",
      [
        title,
        description,
        deadline,
        priority,
        status,
        lastUpdate,
        taskMap['taskID']
      ],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);

      //insert remote activityLog
      var activityDetails = jsonDecode(actMap['activityDetails']);
      var remoteDetail = {
        "table": activityDetails["table"],
        "tableActivity": activityDetails["tableActivity"],
        "newState": activityDetails["newState"],
        "taskID": taskMap['taskID'],
      };
      if (activityDetails['tableActivity'] == 'changeTaskState') {
        await LocalDB.markActivityLogAsVisible(actMap['locId']);
      }

      var logResponse = await DBHelper.query(
          "INSERT INTO activityLog (userID,projectID, activityType, activityDetails) VALUES (?, ?, ?, ?)",
          [
            actMap['userID'],
            actMap['projectID'],
            actMap['activityType'],
            jsonEncode(remoteDetail),
          ]);
    } else {
      AppLog.e("Error updating task in remote database: $response");
    }
  }

  static Future<void> handleRemoteTaskDeletion(
      Map<String, dynamic> deletion) async {
    var activityDetails = jsonDecode(deletion['activityDetails']);
    var remoteID = activityDetails['taskID'] ?? activityDetails['locId'];
    // Verificar si la tarea existe en la base de datos remota
    var existTask = await DBHelper.query(
      "SELECT * FROM tasks WHERE taskID = ?",
      [remoteID],
    );
    var taskMap = existTask.isNotEmpty ? existTask.first : null;
    if (taskMap != null) {
      await DBHelper.query(
        "DELETE FROM tasks WHERE taskID = ?",
        [remoteID],
      );
    }
    var delLocId = deletion['locId'];
    await LocalDB.markActivityLogAsSynced(delLocId);
  }
}
