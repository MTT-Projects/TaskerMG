import 'package:sqflite/sqflite.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/utils/AppLog.dart';

class Attachment {
  int? locId;
  int? attachmentID;
  int? taskCommentID;
  int? userID;
  String? name;
  String? type;
  int? size;
  String? fileUrl;
  String? localPath;
  DateTime? uploadDate;
  DateTime? lastUpdate;

  Attachment(
      {this.locId,
      this.attachmentID,
      this.taskCommentID,
      this.userID,
      this.name,
      this.type,
      this.size,
      this.fileUrl,
      this.localPath,
      this.uploadDate,
      this.lastUpdate});

  Map<String, dynamic> toMap() {
    return {
      'locId': locId,
      'attachmentID': attachmentID,
      'taskCommentID': taskCommentID,
      'userID': userID,
      'name': name,
      'type': type,
      'size': size,
      'fileUrl': fileUrl,
      'localPath': localPath,
      'uploadDate': uploadDate,
      'lastUpdate': lastUpdate,
    };
  }

  //tomap static
  static Map<String, dynamic> toMapStatic(Attachment attachment) {
    return {
      'locId': attachment.locId,
      'attachmentID': attachment.attachmentID,
      'taskCommentID': attachment.taskCommentID,
      'userID': attachment.userID,
      'name': attachment.name,
      'type': attachment.type,
      'size': attachment.size,
      'fileUrl': attachment.fileUrl,
      'localPath': attachment.localPath,
      'uploadDate': attachment.uploadDate,
      'lastUpdate': attachment.lastUpdate,
    };
  }

  static Attachment fromJson(Map<String, dynamic> json) {
    return Attachment(
      locId: json['locId'],
      attachmentID: json['attachmentID'],
      taskCommentID: json['taskCommentID'],
      userID: json['userID'],
      name: json['name'],
      type: json['type'],
      size: json['size'],
      fileUrl: json['fileUrl'],
      localPath: json['localPath'],
      uploadDate: DateTime.parse(json['uploadDate']),
      lastUpdate: DateTime.parse(json['lastUpdate']),
    );
  }

  Map<String, dynamic> toJson() => {
        'locId': locId,
        'attachmentID': attachmentID,
        'taskCommentID': taskCommentID,
        'userID': userID,
        'name': name,
        'type': type,
        'size': size,
        'fileUrl': fileUrl,
        'localPath': localPath,
        'uploadDate': uploadDate?.toIso8601String(),
        'lastUpdate': lastUpdate?.toIso8601String(),
      };

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attachment (
        locId INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        attachmentID INTEGER UNIQUE,
        taskCommentID INT,
        userID INTEGER,
        name VARCHAR(255) NOT NULL,
        type varchar(100) NOT NULL,
        size INTEGER NOT NULL,
        fileUrl VARCHAR(255) NOT NULL,
        localPath VARCHAR(255),
        uploadDate TEXT,
        lastUpdate TEXT,
        FOREIGN KEY (userID) REFERENCES user(userID) ON DELETE CASCADE,
        FOREIGN KEY (taskCommentID) REFERENCES taskComment(taskCommentID) ON DELETE CASCADE
      );
    ''');
    AppLog.d('Table Attachment created');
  }

  static Future<bool> updateAttachmentLocalPath(int attatchmentlocId, String path) async {
    //update local path of attachment
    var result  = await LocalDB.rawUpdate('''
        UPDATE attachment SET localPath = ? WHERE locId = ?
      ''', [path, attatchmentlocId]);

    if (result == 0) {
      return false;
    }
    return true;

  }
}
