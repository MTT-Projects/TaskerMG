import 'package:get/get.dart';
import 'package:taskermg/controllers/dbRelationscontroller.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/models/activity_log.dart';
import 'package:taskermg/models/attachment.dart';
import 'package:taskermg/models/dbRelations.dart';
import 'package:taskermg/models/taskComment.dart';
import 'package:taskermg/services/storage_service.dart';

import '../db/db_local.dart';

class TaskCommentController extends GetxController {
  var commentsList = <TaskComment>[].obs;
  var attachmentsList = <Attachment>[].obs;

  void fetchComments(int taskID) async {
    List<Map<String, dynamic>> commentsData = await LocalDB.rawQuery(
        // 'taskComment',
        // where: 'taskID = ?',
        // whereArgs: [taskID],
        // orderBy: 'timestamp ASC',
        '''
          SELECT * from taskComment where taskID = $taskID order by timestamp ASC
      ''');

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
  }

  static deleteTaskComment(TaskComment taskComment) async {
    // Registrar la actividad
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MainController.getVar('userID'),
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

    // Eliminar adjuntos de comentarios de tareas relacionadas
    await LocalDB.delete("attachment",
        where: 'taskCommentID = ?', whereArgs: [taskComment.locId]);

    // Eliminar el comentario
    await LocalDB.delete("taskComment",
        where: 'commentID = ?', whereArgs: [taskComment.locId]);
  }

  static updateTaskID(int locId, int taskId) {
    LocalDB.update("taskComment", {'taskID': taskId},
        where: 'commentID = ?', whereArgs: [locId]);
  }

  static addTaskComment(TaskComment taskComment) async {
    await DBHelper.query('''
    INSERT INTO taskComment (taskID, userID, comment, timestamp, lastUpdate)
    ''', [
      taskComment.taskID,
      taskComment.userID,
      taskComment.comment,
      taskComment.creationDate,
      taskComment.lastUpdate,
    ]);
  }

  static updateTaskComment(TaskComment taskComment) async {
    await DBHelper.query('''
    UPDATE taskComment
    SET comment = ?, lastUpdate = ?
    WHERE commentID = ?
    ''', [
      taskComment.comment,
      taskComment.lastUpdate,
      taskComment.locId,
    ]);
  }
}
