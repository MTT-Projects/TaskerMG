import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/attachment.dart';
import 'package:taskermg/utils/AppLog.dart';

class SyncAttachment {
  static String formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

  static Future<void> pullAttachments() async {
    var userID = MainController.getVar('currentUser');
    try {
      var result = await DBHelper.query('''
        SELECT 
          a.attachmentID, 
          a.taskCommentID, 
          a.userID, 
          a.name, 
          a.type, 
          a.size, 
          a.fileUrl, 
          a.uploadDate, 
          a.lastUpdate
        FROM 
          attachment a
        JOIN 
          taskComment tc ON a.taskCommentID = tc.taskCommentID
        JOIN 
          taskAssignment ta ON tc.taskID = ta.taskID
        WHERE 
          ta.userID = ?
      ''', [userID]);

      var remoteAttachments = result.map((attachmentMap) => attachmentMap['attachmentID']).toList();
      AppLog.d("Attachments remotos: $remoteAttachments");

      var localAttachments = await LocalDB.query('attachment');
      if (localAttachments.isEmpty) {
        AppLog.d("No hay attachments locales.");
      } else {
        var localAttachmentIDs = localAttachments.map((attachment) => attachment['attachmentID']).toList();

        for (var localAttachmentID in localAttachmentIDs) {
          if (!remoteAttachments.contains(localAttachmentID)) {
            await LocalDB.rawDelete(
              "DELETE FROM attachment WHERE attachmentID = ?",
              [localAttachmentID],
            );
            AppLog.d("Attachment con ID $localAttachmentID marcado como eliminado.");
          }
        }
      }

      for (var attachmentMap in result) {
        var attachmentMapped = Attachment(
          attachmentID: attachmentMap['attachmentID'],
          taskCommentID: attachmentMap['taskCommentID'],
          userID: attachmentMap['userID'],
          name: attachmentMap['name'],
          type: attachmentMap['type'],
          size: attachmentMap['size'],
          fileUrl: attachmentMap['fileUrl'],
          uploadDate: attachmentMap['uploadDate'],
          lastUpdate: attachmentMap['lastUpdate'],
        ).toJson();
        await handleAttachmentSync(attachmentMapped);
      }
      AppLog.d("Attachments obtenidos exitosamente.");
    } catch (e) {
      AppLog.e("Error al obtener attachments: $e");
    }
  }

  static Future<void> pushAttachments() async {
    try {
      var unsyncedAttachments = await LocalDB.queryUnsyncedCreations('attachment');
      AppLog.d("Attachments sin sincronizar: ${jsonEncode(unsyncedAttachments)}");

      for (var actMap in unsyncedAttachments) {
        var details = jsonDecode(actMap['activityDetails']);
        var hasDeletion = await hasDeletionLog(details['attachmentID'] ?? details['locId']);
        if (!hasDeletion) {
          var creationActivity = await getCreationActivityByAttachmentID(details['attachmentID'] ?? details['locId']);
          if (creationActivity != null) {
            if (creationActivity['isSynced'] == 0) {
              await handleRemoteAttachmentInsert(actMap);
            }
          }
        } else {
          await markActivityLogAsSyncedByAttachmentId(details['attachmentID'] ?? details['locId']);
        }
      }

      var unsyncedAttachmentUpdates = await LocalDB.queryUnsyncedUpdates('attachment');
      AppLog.d("Attachments sin actualizar: ${jsonEncode(unsyncedAttachmentUpdates)}");

      for (var actMap in unsyncedAttachmentUpdates) {
        var details = jsonDecode(actMap['activityDetails']);
        var hasDeletion = await hasDeletionLog(actMap['attachmentID'] ?? actMap['locId']);
        if (!hasDeletion) {
          var creationActivity = await getCreationActivityByAttachmentID(actMap['attachmentID'] ?? actMap['locId']);
          if (creationActivity != null) {
            if (creationActivity['isSynced'] == 0) {
              await handleRemoteAttachmentUpdate(actMap);
            }
          } else {
            await handleRemoteAttachmentUpdate(actMap);
          }
        } else {
          await markActivityLogAsSyncedByAttachmentId(details['attachmentID']);
        }
      }

      var unsyncedDeletions = await LocalDB.queryUnsyncedDeletions('attachment');
      AppLog.d("Attachments sin eliminar: ${jsonEncode(unsyncedDeletions)}");

      for (var deletion in unsyncedDeletions) {
        await handleRemoteAttachmentDeletion(deletion);
      }

      AppLog.d("Attachments enviados exitosamente.");
    } catch (e) {
      AppLog.e("Error al enviar attachments: $e");
    }
  }

  static Future<Map<String, dynamic>?> getCreationActivityByAttachmentID(int attachmentID) async {
    var activities = await LocalDB.rawQuery(
      "SELECT * FROM activityLog WHERE activityType = 'create'",
    );
    for (Map<String, dynamic> activity in activities) {
      var details = jsonDecode(activity['activityDetails']);
      var actAttachmentId = details['locId'];
      if (details['table'] == 'attachment' && actAttachmentId == attachmentID) {
        return activity;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getUpdateActivityByAttachmentID(int attachmentID) async {
    var activities = await LocalDB.rawQuery(
      "SELECT * FROM activityLog WHERE activityType = 'update'",
    );
    for (Map<String, dynamic> activity in activities) {
      var details = jsonDecode(activity['activityDetails']);
      var actAttachmentId = details['locId'];
      if (details['table'] == 'attachment' && actAttachmentId == attachmentID) {
        return activity;
      }
    }
    return null;
  }

  static Future<void> handleAttachmentSync(Map<String, dynamic> attachmentMap) async {
    var localAttachment = await LocalDB.queryAttachmentByRemoteID(attachmentMap['attachmentID']);
    if (localAttachment == null) {
      await LocalDB.insertAttachment(Attachment.fromJson(attachmentMap));
    } else {
      if (DateTime.parse(attachmentMap['lastUpdate']).isAfter(DateTime.parse(localAttachment['lastUpdate']))) {
        var updated = Attachment.fromJson(attachmentMap);
        updated.locId = localAttachment['locId'];
        await LocalDB.updateAttachment(updated);
      }
    }
  }

  static Future<bool> hasDeletionLog(int attachmentID) async {
    var deletions = await LocalDB.queryUnsyncedDeletions('attachment');
    for (var deletion in deletions) {
      var details = jsonDecode(deletion['activityDetails']);
      if (details['attachmentID'] == attachmentID || details['locId'] == attachmentID) {
        var creationActivity = await getCreationActivityByAttachmentID(attachmentID);
        if (creationActivity != null) {
          await LocalDB.markActivityLogAsSynced(creationActivity['locId']);
        }
        return true;
      }
    }
    return false;
  }

  static Future<void> markActivityLogAsSyncedByAttachmentId(int attachmentID) async {
    var activities = await LocalDB.queryUnsyncedActivityLogs();
    var filAct = [];
    for (var act in activities) {
      if (act['activityType'] == 'create' || act['activityType'] == 'update') {
        filAct.add(act);
      }
    }

    for (var activity in filAct) {
      var data = jsonDecode(activity['activityDetails']);
      if (data['attachmentID'] == attachmentID || data['locId'] == attachmentID) {
        var updated = await LocalDB.markActivityLogAsSynced(activity['locId']);
        AppLog.d("Actividad de creación marcada como sincronizada: $updated");
      }
    }

    var updates = await LocalDB.queryUnsyncedUpdates('attachment');
    for (var update in updates) {
      var details = jsonDecode(update['activityDetails']);
      if (details['attachmentID'] == attachmentID || details['locId'] == attachmentID) {
        await LocalDB.markActivityLogAsSynced(update['locId']);
      }
    }

    var deletions = await LocalDB.queryUnsyncedDeletions('attachment');
    for (var deletion in deletions) {
      var details = jsonDecode(deletion['activityDetails']);
      if (details['attachmentID'] == attachmentID || details['locId'] == attachmentID) {
        await LocalDB.markActivityLogAsSynced(deletion['locId']);
      }
    }
  }

  static Future<void> handleRemoteAttachmentInsert(Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var attachmentMap = <String, dynamic>{};
    if (actDetails['attachmentID'] != null) {
      attachmentMap = (await LocalDB.queryAttachmentByRemoteID(actDetails['attachmentID']))!;
    } else {
      attachmentMap = (await LocalDB.queryAttachmentByLocalID(actDetails['locId']))!;
    }

    String taskCommentID = attachmentMap['taskCommentID'].toString();
    String userID = attachmentMap['userID'].toString();
    String name = attachmentMap['name'];
    String type = attachmentMap['type'];
    int size = attachmentMap['size'];
    String fileUrl = attachmentMap['fileUrl'];
    String uploadDate = formatDateTime(DateTime.parse(attachmentMap['uploadDate']));
    String lastUpdate = formatDateTime(DateTime.parse(attachmentMap['lastUpdate']));

    var response = await DBHelper.query(
      "INSERT INTO attachment (taskCommentID, userID, name, type, size, fileUrl, uploadDate, lastUpdate) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
      [taskCommentID, userID, name, type, size, fileUrl, uploadDate, lastUpdate],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);
      var insertId = response.insertId;
      if (insertId != null) {
        await LocalDB.updateAttachmentSyncStatus(attachmentMap['locId'], insertId);
      }
    } else {
      AppLog.e("Error inserting attachment in remote database: $response");
    }
  }

  static Future<void> handleRemoteAttachmentUpdate(Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var attachmentMap = <String, dynamic>{};
    if (actDetails['attachmentID'] != null) {
      attachmentMap = (await LocalDB.queryAttachmentByRemoteID(actDetails['attachmentID']))!;
    } else {
      attachmentMap = (await LocalDB.queryAttachmentByLocalID(actDetails['locId']))!;
    }

    if (attachmentMap.isEmpty) {
      AppLog.e("No se encontró el attachment con ID ${actDetails['attachmentID']}");
      return;
    }

    String name = attachmentMap['name'];
    String type = attachmentMap['type'];
    int size = attachmentMap['size'];
    String fileUrl = attachmentMap['fileUrl'];
    String lastUpdate = formatDateTime(DateTime.parse(attachmentMap['lastUpdate']));

    var remoteAttachment = await DBHelper.query(
      "SELECT * FROM attachment WHERE attachmentID = ?",
      [attachmentMap['attachmentID']],
    );
    if (remoteAttachment.isNotEmpty) {
      var remoteLastUpdate = remoteAttachment.first['lastUpdate'];

      var localLastUpdate = DateTime.parse(attachmentMap['lastUpdate']);
      if (remoteLastUpdate.isAfter(localLastUpdate)) {
        AppLog.d("Attachment remoto más reciente, no se actualizará.");
        return;
      }
    }

    var response = await DBHelper.query(
      "UPDATE attachment SET name = ?, type = ?, size = ?, fileUrl = ?, lastUpdate = ? WHERE attachmentID = ?",
      [name, type, size, fileUrl, lastUpdate, attachmentMap['attachmentID']],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);
    } else {
      AppLog.e("Error updating attachment in remote database: $response");
    }
  }

  static Future<void> handleRemoteAttachmentDeletion(Map<String, dynamic> deletion) async {
    var activityDetails = jsonDecode(deletion['activityDetails']);
    var remoteID = activityDetails['attachmentID'] ?? activityDetails['locId'];
    var existAttachment = await DBHelper.query(
      "SELECT * FROM attachment WHERE attachmentID = ?",
      [remoteID],
    );
    var attachmentMap = existAttachment.isNotEmpty ? existAttachment.first : null;
    if (attachmentMap != null) {
      await DBHelper.query(
        "DELETE FROM attachment WHERE attachmentID = ?",
        [remoteID],
      );
    }
    var delLocId = deletion['locId'];
    await LocalDB.markActivityLogAsSynced(delLocId);
  }
}
