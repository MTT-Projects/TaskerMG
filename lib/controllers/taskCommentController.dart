
import 'package:taskermg/controllers/dbRelationscontroller.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/models/activity_log.dart';
import 'package:taskermg/models/attachment.dart';
import 'package:taskermg/models/dbRelations.dart';
import 'package:taskermg/models/taskComment.dart';

import '../db/db_local.dart';

class TaskCommentController{
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
    var attachments = await LocalDB.db.query("taskAttachment", where: 'taskCommentID = ?', whereArgs: [taskComment.taskCommentID ?? taskComment.locId]);
    for (var attachment in attachments) {
      await DbRelationsCtr.deleteTaskAttachment(TaskAttachment.fromJson(attachment));
    }

    // Eliminar el comentario
    await LocalDB.db.delete("taskComment", where: 'commentID = ?', whereArgs: [taskComment.locId]);
  }

  static updateTaskID(int locId, int taskId) {
    LocalDB.db.update("taskComment", {'taskID': taskId}, where: 'commentID = ?', whereArgs: [locId]);
  }

  
}