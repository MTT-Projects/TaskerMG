import 'package:sqflite/sqflite.dart';

import '../utils/AppLog.dart';

class UserProject {
  int? locId;
  int? userProjectID;
  int? userID;
  int? projectID;
  DateTime? lastUpdate;

  UserProject({this.locId, this.userProjectID, this.userID, this.projectID, this.lastUpdate});

  Map<String, dynamic> toMap() {
    return {
      'locId': locId,
      'userProjectID': userProjectID,
      'userID': userID,
      'projectID': projectID,
      'lastUpdate': lastUpdate?.toIso8601String(),
    };
  }

  static UserProject fromJson(Map<String, dynamic> json) {
    return UserProject(
      locId: json['locId'],
      userProjectID: json['userProjectID'],
      userID: json['userID'],
      projectID: json['projectID'],
      lastUpdate: DateTime.parse(json['lastUpdate']),
    );
  }

  //from map
  static UserProject fromMap(Map<String, dynamic> map) {
    return UserProject(
      locId: map['locId'],
      userProjectID: map['userProjectID'],
      userID: map['userID'],
      projectID: map['projectID'],
      lastUpdate: DateTime.parse(map['lastUpdate']),
    );
  }

  Map<String, dynamic> toJson() => {
        'locId': locId,
        'userProjectID': userProjectID,
        'userID': userID,
        'projectID': projectID,
        'lastUpdate': lastUpdate?.toIso8601String(),
      };

  static Future<void> createTable(Database db) async {
    await db.execute('''
      Create table userProject(
        locId INTEGER PRIMARY KEY AUTOINCREMENT,
        userProjectID INT UNIQUE,
        userID INT,
        projectID INT,
        lastUpdate TEXT,
        FOREIGN KEY (userID) REFERENCES user(locId) ON DELETE CASCADE,
        FOREIGN KEY (projectID) REFERENCES project(locId) ON DELETE CASCADE
      );
    ''');
    AppLog.d("Table userProject created");
  }
}

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
Create Table taskComment(
      locId INTEGER PRIMARY KEY AUTOINCREMENT,
      taskCommentID INT UNIQUE,
      taskID INT,
      userID INT,
      comment TEXT,
      creationDate TEXT,
      lastUpdate TEXT,
      FOREIGN KEY (taskID) REFERENCES task(locId) ON DELETE CASCADE,
      FOREIGN KEY (userID) REFERENCES user(locId) ON DELETE CASCADE);
    ''');
    AppLog.d("Table taskComment created");
  }
}

class TaskAssigment {
  int? locId;
  int? taskAssigmentID;
  int? taskID;
  int? userID;
  DateTime? creationDate;
  DateTime? lastUpdate;

  TaskAssigment(
      {this.locId,
      this.taskAssigmentID,
      this.taskID,
      this.userID,
      this.creationDate,
      this.lastUpdate});

  Map<String, dynamic> toMap() {
    return {
      'locId': locId,
      'taskAssigmentID': taskAssigmentID,
      'taskID': taskID,
      'userID': userID,
      'creationDate': creationDate?.toIso8601String(),
      'lastUpdate': lastUpdate?.toIso8601String(),
    };
  }

  static TaskAssigment fromJson(Map<String, dynamic> json) {
    return TaskAssigment(
      locId: json['locId'],
      taskAssigmentID: json['taskAssigmentID'],
      taskID: json['taskID'],
      userID: json['userID'],
      creationDate: DateTime.parse(json['creationDate']),
      lastUpdate: DateTime.parse(json['lastUpdate']),
    );
  }

  Map<String, dynamic> toJson() => {
        'locId': locId,
        'taskAssigmentID': taskAssigmentID,
        'taskID': taskID,
        'userID': userID,
        'creationDate': creationDate?.toIso8601String(),
        'lastUpdate': lastUpdate?.toIso8601String(),
      };

  static Future<void> createTable(Database db) async {
    await db.execute('''
Create Table taskAssigment(
      locId INTEGER PRIMARY KEY AUTOINCREMENT,
      taskAssigmentID INT UNIQUE,
      taskID INT,
      userID INT,
      creationDate TEXT,
      lastUpdate TEXT,
      FOREIGN KEY (taskID) REFERENCES task(locId) ON DELETE CASCADE,
      FOREIGN KEY (userID) REFERENCES user(locId) ON DELETE CASCADE);
    ''');
    AppLog.d("Table taskAssigment created");
  }
}
