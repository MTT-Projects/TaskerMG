import 'dart:convert';
import 'package:googleapis/admob/v1.dart';
import 'package:mysql1/mysql1.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/task_controller.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/dbRelations.dart';
import 'package:taskermg/models/taskComment.dart';
import 'package:taskermg/utils/AppLog.dart';
import 'package:intl/intl.dart';

class SyncTaskComment {
  static String formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

  static Future<void> pullTaskComment() async {
    var userID = MainController.getVar('currentUser');
    try {
      var result = await DBHelper.query('''SELECT *
        FROM 
          taskComment 
        WHERE 
          userID = ?''', [userID]);

      var remoteTaskComments = result
          .map((taskCommentMap) => taskCommentMap['taskCommentID'])
          .toList();
      //fetch local task comments
      var localTaskComments = await LocalDB.queryTaskComments();
      if (localTaskComments.isEmpty) {
        AppLog.d("No hay comentarios de tareas locales.");
      } else {
        var localTaskCommentIDs = localTaskComments
            .map((taskComment) => taskComment['taskCommentID'])
            .toList();

        // Detect deleted task comments
        for (var localTaskCommentID in localTaskCommentIDs) {
          if (!remoteTaskComments.contains(localTaskCommentID)) {
            await LocalDB.rawDelete(
              "DELETE FROM taskComment WHERE taskCommentID = ?",
              [localTaskCommentID],
            );
            AppLog.d(
                "Comentario de tarea con ID $localTaskCommentID marcado como eliminado.");
          }
        }
      }

      for (var taskCommentMap in result) {
        var taskCommentMapped = TaskComment(
          locId: taskCommentMap['locId'],
          taskCommentID: taskCommentMap['taskCommentID'],
          userID: taskCommentMap['userID'],
          taskID: taskCommentMap['taskID'],
          comment: taskCommentMap['comment'],
          lastUpdate: taskCommentMap['lastUpdate'],
        ).toJson();
        await handleTaskCommentSync(taskCommentMapped);
      }
    } catch (e) {
      AppLog.e("Error pulling task comments: $e");
    }
  }

  static Future<void> pushTaskComment() async {
    var userID = MainController.getVar('currentUser');
    try {
      var result = await LocalDB.rawQuery(
        'SELECT * FROM taskComment WHERE userID = ?',
        [userID],
      );

      for (var taskCommentMap in result) {
        var taskCommentMapped = TaskComment(
          locId: taskCommentMap['locId'],
          taskCommentID: taskCommentMap['taskCommentID'],
          userID: taskCommentMap['userID'],
          taskID: taskCommentMap['taskID'],
          comment: taskCommentMap['comment'],
          lastUpdate: taskCommentMap['lastUpdate'],
        ).toJson();
        await handleTaskCommentSync(taskCommentMapped);
      }
    } catch (e) {
      AppLog.e("Error pushing task comments: $e");
    }
  }

  static Future<void> handleTaskCommentSync(Map<String, dynamic> taskComment) async {
    try {
      var taskCommentID = taskComment['taskCommentID'];
      var taskID = taskComment['taskID'];
      var userID = taskComment['userID'];
      var comment = taskComment['comment'];
      var lastUpdate = taskComment['lastUpdate'];

      var result = await DBHelper.query(
        'SELECT * FROM taskComment WHERE taskCommentID = ?',
        [taskCommentID],
      );

      if (result.isNotEmpty) {
        var remoteTaskComment = result.first;
        var remoteTaskID = remoteTaskComment['taskID'];
        var remoteUserID = remoteTaskComment['userID'];
        var remoteComment = remoteTaskComment['comment'];
        var remoteLastUpdate = remoteTaskComment['lastUpdate'];

        if (taskID != remoteTaskID ||
            userID != remoteUserID ||
            comment != remoteComment ||
            lastUpdate != remoteLastUpdate) {
          await DBHelper.query(
            'UPDATE taskComment SET taskID = ?, userID = ?, comment = ?, lastUpdate = ? WHERE taskCommentID = ?',
            [taskID, userID, comment, lastUpdate, taskCommentID],
          );
          AppLog.d("TaskComment updated: $taskCommentID");
        }
      } else {
        await DBHelper.query(
          'INSERT INTO taskComment (taskCommentID, taskID, userID, comment, lastUpdate) VALUES (?, ?, ?, ?, ?)',
          [taskCommentID, taskID, userID, comment, lastUpdate],
        );
        AppLog.d("TaskComment inserted: $taskCommentID");
      }
    } catch (e) {
      AppLog.e("Error handling task comment sync: $e");
    }
  }

  static Future<void> handleRemoteTaskCommentInsert(Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var taskCommentMap = Map<String, dynamic>();
    if (actDetails['taskCommentID'] != null) {
      taskCommentMap = (await LocalDB.queryTaskCommentByRemoteID(
          actDetails['taskCommentID']))!;
    } else {
      taskCommentMap =
          (await LocalDB.queryTaskCommentByLocalID(actDetails['locId']))!;
    }

    String taskID = taskCommentMap['taskID'].toString();
    String userID = taskCommentMap['userID'].toString();
    String comment = taskCommentMap['comment'];
    String lastUpdate =
        formatDateTime(DateTime.parse(taskCommentMap['lastUpdate']));

    var response = await DBHelper.query(
      "INSERT INTO taskComment (taskID, userID, comment, lastUpdate) VALUES (?, ?, ?, ?)",
      [taskID, userID, comment, lastUpdate],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);
      var insertId = response.insertId;
      if (insertId != null) {
        await LocalDB.updateTaskCommentSyncStatus(
            taskCommentMap['locId'], insertId);
      }
    } else {
      AppLog.e("Error inserting task comment in remote database: $response");
    }
  }

  static Future<void> handleRemoteTaskCommentUpdate(Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var taskCommentMap = Map<String, dynamic>();
    if (actDetails['taskCommentID'] != null) {
      taskCommentMap = (await LocalDB.queryTaskCommentByRemoteID(
          actDetails['taskCommentID']))!;
    } else {
      taskCommentMap =
          (await LocalDB.queryTaskCommentByLocalID(actDetails['locId']))!;
    }

    String taskID = taskCommentMap['taskID'].toString();
    String userID = taskCommentMap['userID'].toString();
    String comment = taskCommentMap['comment'];
    String lastUpdate =
        formatDateTime(DateTime.parse(taskCommentMap['lastUpdate']));

    var response = await DBHelper.query(
      "UPDATE taskComment SET taskID = ?, userID = ?, comment = ?, lastUpdate = ? WHERE taskCommentID = ?",
      [taskID, userID, comment, lastUpdate, taskCommentMap['taskCommentID']],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);
    } else {
      AppLog.e("Error updating task comment in remote database: $response");
    }
  }

  static Future<void> handleRemoteTaskCommentDelete(Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var taskCommentMap = Map<String, dynamic>();
    if (actDetails['taskCommentID'] != null) {
      taskCommentMap = (await LocalDB.queryTaskCommentByRemoteID(
          actDetails['taskCommentID']))!;
    } else {
      taskCommentMap =
          (await LocalDB.queryTaskCommentByLocalID(actDetails['locId']))!;
    }

    var response = await DBHelper.query(
      "DELETE FROM taskComment WHERE taskCommentID = ?",
      [taskCommentMap['taskCommentID']],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);
    } else {
      AppLog.e("Error deleting task comment in remote database: $response");
    }
  }

  static Future<void> handleRemoteTaskCommentSync(Map<String, dynamic> actMap) async {
    var actType = actMap['activityType'];
    if (actType == 'taskCommentInsert') {
      await handleRemoteTaskCommentInsert(actMap);
    } else if (actType == 'taskCommentUpdate') {
      await handleRemoteTaskCommentUpdate(actMap);
    } else if (actType == 'taskCommentDelete') {
      await handleRemoteTaskCommentDelete(actMap);
    }
  }

  static Future<void> syncTaskComment() async {
    await pullTaskComment();
    await pushTaskComment();
  }


}