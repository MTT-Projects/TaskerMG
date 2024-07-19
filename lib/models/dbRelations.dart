import 'package:sqflite/sqflite.dart';

import '../utils/AppLog.dart';

class UserProject {
  int? locId;
  int? userProjectID;
  int? userID;
  int? projectID;
  DateTime? lastUpdate;

  UserProject(
      {this.locId,
      this.userProjectID,
      this.userID,
      this.projectID,
      this.lastUpdate});

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
      Create table IF NOT EXISTS userProject(
        locId INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        userProjectID INTEGER UNIQUE,
        userID INTEGER,
        projectID INTEGER,
        lastUpdate TEXT,
        FOREIGN KEY (userID) REFERENCES user(locId) ON DELETE CASCADE,
        FOREIGN KEY (projectID) REFERENCES project(locId) ON DELETE CASCADE
      );
    ''');
    AppLog.d("Table userProject created");
  }
}

class TaskAssignment {
  int? locId;
  int? assignmentID;
  int? taskID;
  int? userID;
  DateTime? creationDate;
  DateTime? lastUpdate;

  TaskAssignment(
      {this.locId,
      this.assignmentID,
      this.taskID,
      this.userID,
      this.creationDate,
      this.lastUpdate});

  Map<String, dynamic> toMap() {
    return {
      'locId': locId,
      'assignmentID': assignmentID,
      'taskID': taskID,
      'userID': userID,
      'creationDate': creationDate?.toIso8601String(),
      'lastUpdate': lastUpdate?.toIso8601String(),
    };
  }

  static TaskAssignment fromJson(Map<String, dynamic> json) {
    return TaskAssignment(
      locId: json['locId'],
      assignmentID: json['assignmentID'],
      taskID: json['taskID'],
      userID: json['userID'],
      creationDate: DateTime.parse(json['creationDate']),
      lastUpdate: DateTime.parse(json['lastUpdate']),
    );
  }

  Map<String, dynamic> toJson() => {
        'locId': locId,
        'assignmentID': assignmentID,
        'taskID': taskID,
        'userID': userID,
        'creationDate': creationDate?.toIso8601String(),
        'lastUpdate': lastUpdate?.toIso8601String(),
      };

  static Future<void> createTable(Database db) async {
    await db.execute('''
Create Table IF NOT EXISTS taskAssignment(
      locId INTEGER PRIMARY KEY AUTOINCREMENT,
      assignmentID INTEGER UNIQUE,
      taskID INTEGER,
      userID INTEGER,
      creationDate TEXT,
      lastUpdate TEXT,
      FOREIGN KEY (taskID) REFERENCES task(locId) ON DELETE CASCADE,
      FOREIGN KEY (userID) REFERENCES user(locId) ON DELETE CASCADE);
    ''');
    AppLog.d("Table taskAssigment created");
  }

  static updateTaskID(int locId, int taskId) {}
}


