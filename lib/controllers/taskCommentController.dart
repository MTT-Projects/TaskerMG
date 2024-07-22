import 'dart:convert';

import 'package:get/get.dart';
import 'package:taskermg/controllers/attatchmentController.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/sync_controller.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/models/activity_log.dart';
import 'package:taskermg/models/attachment.dart';
import 'package:taskermg/models/taskComment.dart';
import 'package:taskermg/services/storage_service.dart';
import 'package:taskermg/utils/FilesManager.dart';
import 'package:taskermg/db/db_local.dart';

class TaskCommentController extends GetxController {
  var commentsList = <TaskComment>[].obs;
  var attachmentsList = <Attachment>[].obs;
  FileManager fileManager = FileManager();

  Future<void> fetchComments(int taskID) async {
    commentsList.value = [];
    attachmentsList.value = [];
    List<Map<String, dynamic>> commentsData = await LocalDB.rawQuery(
      "SELECT * FROM taskComment WHERE taskID = ? ORDER BY creationDate ASC",
      [taskID],
    );

    List<TaskComment> comments =
        commentsData.map((data) => TaskComment.fromJson(data)).toList();
    commentsList.value = comments;

    for (var comment in comments) {
      List<Map<String, dynamic>> attachmentsData = await LocalDB.query(
        'attachment',
        where: 'taskCommentID = ?',
        whereArgs: [comment.taskCommentID],
      );

      List<Attachment> attachments =
          attachmentsData.map((data) => Attachment.fromJson(data)).toList();
      attachmentsList.addAll(attachments);
    }
    //wait two seconds
    await Future.delayed(Duration(seconds: 1));
    return;
  }

  static Future<void> deleteTaskComment(TaskComment taskComment) async {
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MainController.getVar('currentUser'),
      projectID: taskComment.taskID,
      activityType: 'delete',
      activityDetails: {
        'table': 'taskComment',
        'locId': taskComment.locId,
        'taskCommentID': taskComment.taskCommentID,
      },
      timestamp: DateTime.now().toUtc(),
      lastUpdate: DateTime.now().toUtc(),
    ));

    await LocalDB.delete("attachment", where: 'taskCommentID = ?', whereArgs: [taskComment.taskCommentID ??taskComment.locId]);
    await LocalDB.delete("taskComment", where: 'locId = ?', whereArgs: [taskComment.locId]);
  }

  static Future<void> deleteComment(TaskComment taskComment) async {
    int userID = MainController.getVar('currentUser');
    DateTime now = DateTime.now().toUtc();

    // Registrar la actividad de eliminación
    await LocalDB.insertActivityLog(ActivityLog(
      userID: userID,
      projectID: taskComment.taskID,
      activityType: 'delete',
      activityDetails: {
        'table': 'taskComment',
        'locId': taskComment.locId,
        'taskCommentID': taskComment.taskCommentID,
      },
      timestamp: now,
      lastUpdate: now,
    ));

    // Eliminar los adjuntos relacionados con el comentario
    List<Map<String, dynamic>> attachmentsData = await LocalDB.query(
      'attachment',
      where: 'taskCommentID = ?',
      whereArgs: [taskComment.taskCommentID ?? taskComment.locId],
    );

    for (var attachmentData in attachmentsData) {
      Attachment attachment = Attachment.fromJson(attachmentData);
      await AttachmentController.deleteAttachment(attachment);
    }

    // Eliminar el comentario
    await LocalDB.delete("taskComment", where: 'locId = ?', whereArgs: [taskComment.locId]);

    await SyncController.pushData();
  }

  static Future<void> updateTaskComment(TaskComment taskComment) async {
    await LocalDB.update('taskComment', taskComment.toJson(), where: 'locId = ?', whereArgs: [taskComment.locId]);
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MainController.getVar('currentUser'),
      projectID: taskComment.taskID,
      activityType: 'update',
      activityDetails: {
        'table': 'taskComment',
        'locId': taskComment.locId,
        'taskCommentID': taskComment.taskCommentID,
      },
      timestamp: DateTime.now().toUtc(),
      lastUpdate: DateTime.now().toUtc(),
    ));
  }

  static Future<int> addTaskComment(TaskComment taskComment) async {
    int locId = await LocalDB.insert('taskComment', taskComment.toJson());
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MainController.getVar('currentUser'),
      projectID: taskComment.taskID,
      activityType: 'create',
      activityDetails: {
        'table': 'taskComment',
        'locId': locId,
        'taskCommentID': taskComment.taskCommentID,
      },
      timestamp: DateTime.now().toUtc(),
      lastUpdate: DateTime.now().toUtc(),
    ));
    return locId;
  }

  Future<void> addComment(int taskId, String commentText, Map<String, dynamic>? file) async {
    int userID = MainController.getVar('currentUser');
    DateTime now = DateTime.now().toUtc();

    TaskComment taskComment = TaskComment(
      taskID: taskId,
      userID: userID,
      comment: commentText,
      creationDate: now,
      lastUpdate: now,
    );

    var commentID = await addTaskComment(taskComment);

    if (file != null) {
      var userId = MainController.getVar('currentUser').toString();
      String fileUrl = await fileManager.uploadFile(file["file"], userId , file['name'], "attachments");
      String localPath = await fileManager.copyFileToLocalPath(file, "attachments");

      Attachment attachment = Attachment(
        taskCommentID: commentID,
        userID: userID,
        name: file['name'],
        type: file['type'],
        size: file['size'],
        fileUrl: fileUrl,
        localPath: localPath,
        uploadDate: now,
        lastUpdate: now,
      );

      await AttachmentController.addAttachment(attachment);
      
    }
    //inser activity log
    await LocalDB.insertActivityLog(ActivityLog(
      userID: userID,
      projectID: taskId,
      activityType: 'create',
      activityDetails: {
        'table': 'taskComment',
        'locId': commentID,
        'taskCommentID': commentID,
      },
      timestamp: now,
      lastUpdate: now,
    ));

    await SyncController.pushData();
  }

  static updateTaskID(int locId, int taskId) {
    LocalDB.update("taskComment", {'taskID': taskId},
        where: 'commentID = ?', whereArgs: [locId]);
  }
}
