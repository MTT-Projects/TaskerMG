import 'package:sqflite/sqflite.dart';
import '../utils/AppLog.dart';

class Task {
  int? id;
  int? projectID;
  String? title;
  String? description;
  DateTime? deadline;
  String? priority;
  String? status;
  int? createdUserID;
  DateTime? lastUpdate;

  Task({
    this.id,
    this.projectID,
    this.title,
    this.description,
    this.deadline,
    this.priority,
    this.status,
    this.createdUserID,
    this.lastUpdate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
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

  Task.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    projectID = json['projectID'];
    title = json['title'];
    description = json['description'];
    deadline = json['deadline'] != null ? DateTime.parse(json['deadline']) : null;
    priority = json['priority'];
    status = json['status'];
    createdUserID = json['createdUserID'];
    lastUpdate = json['lastUpdate'] != null ? DateTime.parse(json['lastUpdate']) : null;
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      projectID: map['projectID'],
      title: map['title'],
      description: map['description'],
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      priority: map['priority'],
      status: map['status'],
      createdUserID: map['createdUserID'],
      lastUpdate: map['lastUpdate'] != null ? DateTime.parse(map['lastUpdate']) : null,
    );
  }

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
    AppLog.i('Table tasks created');
  }
}

