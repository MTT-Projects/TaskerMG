import 'package:sqflite/sqflite.dart';

import '../utils/AppLog.dart';

class TaskComment {
  int? locId;
  int? taskCommentID;
  int? taskID;
  int? userID;
  String? comment;
  DateTime? creationDate;
  DateTime? lastUpdate;

  TaskComment(
      {this.locId,
      this.taskCommentID,
      this.taskID,
      this.userID,
      this.comment,
      this.creationDate,
      this.lastUpdate});

  Map<String, dynamic> toMap() {
    return {
      'locId': locId,
      'taskCommentID': taskCommentID,
      'taskID': taskID,
      'userID': userID,
      'comment': comment,
      'creationDate': creationDate?.toIso8601String(),
      'lastUpdate': lastUpdate?.toIso8601String(),
    };
  }

  static TaskComment fromJson(Map<String, dynamic> json) {
    return TaskComment(
      locId: json['locId'],
      taskCommentID: json['taskCommentID'],
      taskID: json['taskID'],
      userID: json['userID'],
      comment: json['comment'],
      creationDate: DateTime.parse(json['creationDate']),
      lastUpdate: DateTime.parse(json['lastUpdate']),
    );
  }

  Map<String, dynamic> toJson() => {
        'locId': locId,
        'taskCommentID': taskCommentID,
        'taskID': taskID,
        'userID': userID,
        'comment': comment,
        'creationDate': creationDate?.toIso8601String(),
        'lastUpdate': lastUpdate?.toIso8601String(),
      };

  static Future<void> createTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS taskComment (
    locId INTEGER PRIMARY KEY AUTOINCREMENT,
    taskCommentID INTEGER,
    taskID INTEGER,
    userID INTEGER,
    comment TEXT,
    creationDate TEXT,
    lastUpdate TEXT,
    FOREIGN KEY (taskID) REFERENCES tasks(taskID) ON DELETE CASCADE,
    FOREIGN KEY (userID) REFERENCES user(userID) ON DELETE CASCADE
);
    ''');
    AppLog.d("Table taskComment created");
  }
}
