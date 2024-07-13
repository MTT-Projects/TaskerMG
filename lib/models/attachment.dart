import 'package:sqflite/sqflite.dart';

class Attachment
{
  int? locId;
  int? attachmentID;
  int? userID;
  String? name;
  String? type;
  int? size;
  String? fileUrl;
  String? localPath;
  String? uploadDate;
  String? lastUpdate;

  Attachment({this.locId, this.attachmentID, this.userID, this.name, this.type, this.size, this.fileUrl, this.localPath, this.uploadDate, this.lastUpdate});

  Map<String, dynamic> toMap() {
    return {
      'locId': locId,
      'attachmentID': attachmentID,
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
      userID: json['userID'],
      name: json['name'],
      type: json['type'],
      size: json['size'],
      fileUrl: json['fileUrl'],
      localPath: json['localPath'],
      uploadDate: json['uploadDate'],
      lastUpdate: json['lastUpdate'],
    );
  }

  Map<String, dynamic> toJson() => {
        'locId': locId,
        'attachmentID': attachmentID,
        'userID': userID,
        'name': name,
        'type': type,
        'size': size,
        'fileUrl': fileUrl,
        'localPath': localPath,
        'uploadDate': uploadDate,
        'lastUpdate': lastUpdate,
      };


  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE attachment (
    locId INTEGER PRIMARY KEY AUTOINCREMENT,
    attachmentID INT UNIQUE,
    userID INT,
    name VARCHAR(255) NOT NULL,
    type varchar(100) NOT NULL,
    size INT NOT NULL,
    fileUrl VARCHAR(255) NOT NULL,
    localPath VARCHAR(255),
    uploadDate TEXT,
    lastUpdate TEXT,
    FOREIGN KEY (userID) REFERENCES user(userID) ON DELETE CASCADE
);
    ''');
  }
}