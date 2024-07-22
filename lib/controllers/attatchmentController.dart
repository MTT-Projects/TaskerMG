import 'package:get/get.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/sync_controller.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/activity_log.dart';
import 'package:taskermg/models/attachment.dart';
import 'package:taskermg/services/storage_service.dart';
import 'package:taskermg/utils/FilesManager.dart';

class AttachmentController extends GetxController {
  var attachmentsList = <Attachment>[].obs;
  FileManager fileManager = FileManager();

  void fetchAttachments(int taskCommentID) async {
    List<Map<String, dynamic>> attachmentsData = await LocalDB.query(
      'attachment',
      where: 'taskCommentID = ?',
      whereArgs: [taskCommentID],
    );

    List<Attachment> attachments =
        attachmentsData.map((data) => Attachment.fromJson(data)).toList();
    attachmentsList.value = attachments;
  }

  static Future<void> deleteAttachment(Attachment attachment) async {
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MainController.getVar('currentUser'),
      projectID: attachment.taskCommentID,
      activityType: 'delete',
      activityDetails: {
        'table': 'attachment',
        'locId': attachment.locId,
        'attachmentID': attachment.attachmentID,
      },
      timestamp: DateTime.now().toUtc(),
      lastUpdate: DateTime.now().toUtc(),
    ));

    await LocalDB.delete("attachment", where: 'locId = ?', whereArgs: [attachment.locId]);
  }

  static Future<void> updateAttachment(Attachment attachment) async {
    await LocalDB.update('attachment', attachment.toJson(), where: 'locId = ?', whereArgs: [attachment.locId]);
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MainController.getVar('currentUser'),
      projectID: attachment.taskCommentID,
      activityType: 'update',
      activityDetails: {
        'table': 'attachment',
        'locId': attachment.locId,
        'attachmentID': attachment.attachmentID,
      },
      timestamp: DateTime.now().toUtc(),
      lastUpdate: DateTime.now().toUtc(),
    ));
  }

  static Future<void> addAttachment(Attachment attachment) async {
    int locId = await LocalDB.insert('attachment', attachment.toJson());
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MainController.getVar('currentUser'),
      projectID: attachment.taskCommentID,
      activityType: 'create',
      activityDetails: {
        'table': 'attachment',
        'locId': locId,
        'attachmentID': null,
      },
      timestamp: DateTime.now().toUtc(),
      lastUpdate: DateTime.now().toUtc(),
    ));
  }

  static Future<void> addAttachmentToComment(int taskCommentID, Map<String, dynamic> file) async {
    FileManager fileManager = FileManager();
    int userID = MainController.getVar('currentUser');
    DateTime now = DateTime.now().toUtc();

    String fileUrl = await fileManager.uploadFile(file['path'], 'attachment', file['name'], "attachments");
    String localPath = await fileManager.copyFileToLocalPath(file, "attachments");

    Attachment attachment = Attachment(
      attachmentID: null,
      taskCommentID: taskCommentID,
      userID: userID,
      name: file['name'],
      type: file['type'],
      size: file['size'],
      fileUrl: fileUrl,
      localPath: localPath,
      uploadDate: now,
      lastUpdate: now,
    );
    await addAttachment(attachment);
  }

  //change attatchment local path
  Future<void> changeAttachmentLocalPath(int attachmentID, String localPath) async {
    Attachment attachment = attachmentsList.firstWhere((element) => element.locId == attachmentID);
    attachment.localPath = localPath;
    await updateAttachment(attachment);
  }

  static updateTaskCommentID(int locId, int taskCommentId) {
    LocalDB.update("attachment", {'taskCommentID': taskCommentId}, where: 'locId = ?', whereArgs: [locId]);
  }

}
