import 'package:sqflite/sqflite.dart';

class Task {
  int? locId;
  int? taskID;
  int? projectID;
  String? title;
  String? description;
  DateTime? deadline;
  String? priority;
  String? status;
  int? createdUserID;
  DateTime? lastUpdate;

  Task({
    this.locId,
    this.taskID,
    this.projectID,
    this.title,
    this.description,
    this.deadline,
    this.priority = 'Media',
    this.status = 'Pendiente',
    this.createdUserID,
    this.lastUpdate,
  });

  Map<String, dynamic> toMap() {
    return {
      'loc_id': locId,
      'taskID': taskID,
      'projectID': projectID,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'priority': priority,
      'status': status,
      'createdUserID': createdUserID,
      'lastUpdate': lastUpdate?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      locId: json['loc_id'],
      taskID: json['taskID'],
      projectID: json['projectID'],
      title: json['title'],
      description: json['description'],
      deadline: DateTime.parse(json['deadline']),
      priority: json['priority'],
      status: json['status'],
      createdUserID: json['createdUserID'],
      lastUpdate: DateTime.parse(json['lastUpdate']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['loc_id'] = locId;
    data['projectID'] = projectID;
    data['title'] = title;
    data['description'] = description;
    data['deadline'] = deadline?.toIso8601String();
    data['priority'] = priority;
    data['status'] = status;
    data['createdUserID'] = createdUserID;
    data['lastUpdate'] = lastUpdate?.toIso8601String();
    return data;
  }

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE tasks (
        loc_id INTEGER PRIMARY KEY AUTOINCREMENT,
        taskID INTEGER,
        projectID INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        deadline TEXT,
        priority TEXT DEFAULT 'Media' CHECK(priority IN ('Baja', 'Media', 'Alta')),
        status TEXT DEFAULT 'Pendiente' CHECK(status IN ('Pendiente', 'En Proceso', 'Completada')),
        createdUserID INTEGER,
        lastUpdate TEXT,
        FOREIGN KEY (projectID) REFERENCES project(projectID) ON DELETE CASCADE,
        FOREIGN KEY (createdUserID) REFERENCES user(userID) ON DELETE CASCADE
      );
    ''');
  }
}
