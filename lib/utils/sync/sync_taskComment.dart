import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/taskComment.dart';
import 'package:taskermg/utils/AppLog.dart';

class SyncTaskComment {
  static String formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

  static Future<void> pullTaskComments() async {
    var userID = MainController.getVar('currentUser');
    try {
      var result = await DBHelper.query('''
        SELECT 
            tc.taskCommentID, 
            tc.taskID, 
            tc.userID, 
            tc.comment, 
            tc.creationDate, 
            tc.lastUpdate
        FROM 
            taskComment tc
        JOIN 
            tasks t ON tc.taskID = t.taskID
        JOIN 
            project p ON t.projectID = p.projectID
        JOIN 
            userProject up ON p.projectID = up.projectID
        WHERE 
            up.userID = ?
      ''', [userID]);

      var remoteTaskComments =
          result.map((commentMap) => commentMap['taskCommentID']).toList();
      AppLog.d("Comentarios remotos: $remoteTaskComments");

      // Fetch local task comments
      var localTaskComments = await LocalDB.query('taskComment');
      if (localTaskComments.isEmpty) {
        AppLog.d("No hay comentarios locales.");
      } else {
        var localTaskCommentIDs = localTaskComments
            .map((comment) => comment['taskCommentID'])
            .toList();

        // Detect deleted comments
        for (var localTaskCommentID in localTaskCommentIDs) {
          if (!remoteTaskComments.contains(localTaskCommentID)) {
            await LocalDB.rawDelete(
              "DELETE FROM taskComment WHERE taskCommentID = ?",
              [localTaskCommentID],
            );
            AppLog.d(
                "Comentario con ID $localTaskCommentID marcado como eliminado.");
          }
        }
      }

      for (var commentMap in result) {
        var commentMapped = TaskComment(
          taskCommentID: commentMap['taskCommentID'],
          taskID: commentMap['taskID'],
          userID: commentMap['userID'],
          comment: commentMap['comment'].toString(),
          creationDate: commentMap['creationDate'],
          lastUpdate: commentMap['lastUpdate'],
        ).toJson();
        await handleCommentSync(commentMapped);
      }
      AppLog.d("Comentarios obtenidos exitosamente.");
    } catch (e) {
      AppLog.e("Error al obtener comentarios: $e");
    }
  }

  static Future<void> pushTaskComments() async {
    try {
      var unsyncedComments =
          await LocalDB.queryUnsyncedCreations('taskComment');
      AppLog.d("Comentarios sin sincronizar: ${jsonEncode(unsyncedComments)}");

      for (var actMap in unsyncedComments) {
        var details = jsonDecode(actMap['activityDetails']);
        var hasDeletion =
            await hasDeletionLog(details['taskCommentID'] ?? details['locId']);
        if (!hasDeletion) {
          var creationActivity = await getCreationActivityByCommentID(
              details['taskCommentID'] ?? details['locId']);
          if (creationActivity != null) {
            if (creationActivity['isSynced'] == 0) {
              await handleRemoteCommentInsert(actMap);
            }
          }
        } else {
          await markActivityLogAsSyncedByCommentId(
              details['taskCommentID'] ?? details['locId']);
        }
      }

      var unsyncedCommentUpdates =
          await LocalDB.queryUnsyncedUpdates('taskComment');
      AppLog.d(
          "Comentarios sin actualizar: ${jsonEncode(unsyncedCommentUpdates)}");

      for (var actMap in unsyncedCommentUpdates) {
        var details = jsonDecode(actMap['activityDetails']);
        var hasDeletion =
            await hasDeletionLog(actMap['taskCommentID'] ?? actMap['locId']);
        if (!hasDeletion) {
          var creationActivity = await getCreationActivityByCommentID(
              actMap['taskCommentID'] ?? actMap['locId']);
          if (creationActivity != null) {
            if (creationActivity['isSynced'] == 0) {
              await handleRemoteCommentUpdate(actMap);
            }
          } else {
            await handleRemoteCommentUpdate(actMap);
          }
        } else {
          await markActivityLogAsSyncedByCommentId(details['taskCommentID']);
        }
      }

      var unsyncedDeletions =
          await LocalDB.queryUnsyncedDeletions('taskComment');
      AppLog.d("Comentarios sin eliminar: ${jsonEncode(unsyncedDeletions)}");

      for (var deletion in unsyncedDeletions) {
        await handleRemoteCommentDeletion(deletion);
      }

      AppLog.d("Comentarios enviados exitosamente.");
    } catch (e) {
      AppLog.e("Error al enviar comentarios: $e");
    }
  }

  //get creation activity by taskCommentID
  static Future<Map<String, dynamic>?> getCreationActivityByCommentID(
      int taskCommentID) async {
    var activities = await LocalDB.rawQuery(
      "SELECT * FROM activityLog WHERE activityType = 'create'",
    );
    for (Map<String, dynamic> activity in activities) {
      var details = jsonDecode(activity['activityDetails']);

      var actCommentId = details['locId'];
      if (details['table'] == 'taskComment' && actCommentId == taskCommentID) {
        return activity;
      }
    }
    return null;
  }

  //get update activity by taskCommentID
  static Future<Map<String, dynamic>?> getUpdateActivityByCommentID(
      int taskCommentID) async {
    var activities = await LocalDB.rawQuery(
      "SELECT * FROM activityLog WHERE activityType = 'update'",
    );
    for (Map<String, dynamic> activity in activities) {
      var details = jsonDecode(activity['activityDetails']);

      var actCommentId = details['locId'];
      if (details['table'] == 'taskComment' && actCommentId == taskCommentID) {
        return activity;
      }
    }
    return null;
  }

  static Future<void> handleCommentSync(Map<String, dynamic> commentMap) async {
    var localComment =
        await LocalDB.queryTaskCommentByRemoteID(commentMap['taskCommentID']);
    if (localComment == null) {
      await LocalDB.insertTaskComment(TaskComment.fromJson(commentMap));
    } else {
      if (DateTime.parse(commentMap['lastUpdate'])
          .isAfter(DateTime.parse(localComment['lastUpdate']))) {
        var updated = TaskComment.fromJson(commentMap);
        updated.locId = localComment['locId'];
        await LocalDB.updateTaskComment(updated);
      }
    }
  }

  static Future<bool> hasDeletionLog(int taskCommentId) async {
    var deletions = await LocalDB.queryUnsyncedDeletions('taskComment');
    for (var deletion in deletions) {
      var details = jsonDecode(deletion['activityDetails']);
      if (details['taskCommentID'] == taskCommentId ||
          details['locId'] == taskCommentId) {
        var creationActivity =
            await getCreationActivityByCommentID(taskCommentId);
        if (creationActivity != null) {
          await LocalDB.markActivityLogAsSynced(creationActivity['locId']);
        }
        return true;
      }
    }
    return false;
  }

  static Future<void> markActivityLogAsSyncedByCommentId(
      int taskCommentId) async {
    var activities = await LocalDB.queryUnsyncedActivityLogs();
    var filAct = [];
    for (var act in activities) {
      if (act['activityType'] == 'create' || act['activityType'] == 'update') {
        filAct.add(act);
      }
    }

    for (var activity in filAct) {
      var data = jsonDecode(activity['activityDetails']);
      if (data['taskCommentID'] == taskCommentId ||
          data['locId'] == taskCommentId) {
        var updated = await LocalDB.markActivityLogAsSynced(activity['locId']);
        AppLog.d("Actividad de creación marcada como sincronizada: $updated");
      }
    }

    var updates = await LocalDB.queryUnsyncedUpdates('taskComment');
    for (var update in updates) {
      var details = jsonDecode(update['activityDetails']);
      if (details['taskCommentID'] == taskCommentId ||
          details['locId'] == taskCommentId) {
        await LocalDB.markActivityLogAsSynced(update['locId']);
      }
    }

    var deletions = await LocalDB.queryUnsyncedDeletions('taskComment');
    for (var deletion in deletions) {
      var details = jsonDecode(deletion['activityDetails']);
      if (details['taskCommentID'] == taskCommentId ||
          details['locId'] == taskCommentId) {
        await LocalDB.markActivityLogAsSynced(deletion['locId']);
      }
    }
  }

  static Future<void> handleRemoteCommentInsert(
      Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var commentMap = <String, dynamic>{};

    commentMap =
        (await LocalDB.queryTaskCommentByLocalID(actDetails['locId']))!;

    String taskID = commentMap['taskID'].toString();
    String userID = commentMap['userID'].toString();
    String comment = commentMap['comment'];
    String creationDate =
        formatDateTime(DateTime.parse(commentMap['creationDate']));
    String lastUpdate =
        formatDateTime(DateTime.parse(commentMap['lastUpdate']));

    var response = await DBHelper.query(
      "INSERT INTO taskComment (taskID, userID, comment, creationDate, lastUpdate) VALUES (?, ?, ?, ?, ?)",
      [taskID, userID, comment, creationDate, lastUpdate],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);
      var insertId = response.insertId;
      if (insertId != null) {
        await LocalDB.updateTaskCommentSyncStatus(
            commentMap['locId'], insertId);
      }
    } else {
      AppLog.e("Error inserting taskComment in remote database: $response");
    }
  }

  static Future<void> handleRemoteCommentUpdate(
      Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var commentMap = <String, dynamic>{};
    if (actDetails['taskCommentID'] != null) {
      commentMap = (await LocalDB.queryTaskCommentByRemoteID(
          actDetails['taskCommentID']))!;
    } else {
      commentMap =
          (await LocalDB.queryTaskCommentByLocalID(actDetails['locId']))!;
    }

    if (commentMap.isEmpty) {
      AppLog.e(
          "No se encontró el comentario con ID ${actDetails['taskCommentID']}");
      return;
    }

    String comment = commentMap['comment'];
    String lastUpdate =
        formatDateTime(DateTime.parse(commentMap['lastUpdate']));

    var remoteComment = await DBHelper.query(
      "SELECT * FROM taskComment WHERE taskCommentID = ?",
      [commentMap['taskCommentID']],
    );
    if (remoteComment.isNotEmpty) {
      var remoteLastUpdate = remoteComment.first['lastUpdate'];

      var localLastUpdate = DateTime.parse(commentMap['lastUpdate']);
      if (remoteLastUpdate.isAfter(localLastUpdate)) {
        AppLog.d("Comentario remoto más reciente, no se actualizará.");
        return;
      }
    }

    var response = await DBHelper.query(
      "UPDATE taskComment SET comment = ?, lastUpdate = ? WHERE taskCommentID = ?",
      [comment, lastUpdate, commentMap['taskCommentID']],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);
    } else {
      AppLog.e("Error updating taskComment in remote database: $response");
    }
  }

  static Future<void> handleRemoteCommentDeletion(
      Map<String, dynamic> deletion) async {
    var activityDetails = jsonDecode(deletion['activityDetails']);
    var remoteID = activityDetails['taskCommentID'] ?? activityDetails['locId'];
    var existComment = await DBHelper.query(
      "SELECT * FROM taskComment WHERE taskCommentID = ?",
      [remoteID],
    );
    var commentMap = existComment.isNotEmpty ? existComment.first : null;
    if (commentMap != null) {
      await DBHelper.query(
        "DELETE FROM taskComment WHERE taskCommentID = ?",
        [remoteID],
      );
    }
    var delLocId = deletion['locId'];
    await LocalDB.markActivityLogAsSynced(delLocId);
  }
}
