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
  DateTime? creationDate;

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
    this.creationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'locId': locId,
      'taskID': taskID,
      'projectID': projectID,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'priority': priority,
      'status': status,
      'createdUserID': createdUserID,
      'lastUpdate': lastUpdate?.toIso8601String(),
      'creationDate': creationDate?.toIso8601String(),
    };
  }

  //toMapStatic
  static Map<String, dynamic> toMapStatic(Task task) {
    return {
      'locId': task.locId,
      'taskID': task.taskID,
      'projectID': task.projectID,
      'title': task.title,
      'description': task.description,
      'deadline': task.deadline?.toIso8601String(),
      'priority': task.priority,
      'status': task.status,
      'createdUserID': task.createdUserID,
      'lastUpdate': task.lastUpdate?.toIso8601String(),
      'creationDate': task.creationDate?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      locId: json['locId'],
      taskID: json['taskID'],
      projectID: json['projectID'],
      title: json['title'],
      description: json['description'],
      deadline: DateTime.parse(json['deadline'].toString()),
      priority: json['priority'],
      status: json['status'],
      createdUserID: json['createdUserID'],
      lastUpdate: DateTime.parse(json['lastUpdate'].toString()),
      creationDate: DateTime.parse(json['creationDate'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['locId'] = locId;
    data['taskID'] = taskID;
    data['projectID'] = projectID;
    data['title'] = title;
    data['description'] = description;
    data['deadline'] = deadline?.toIso8601String();
    data['priority'] = priority;
    data['status'] = status;
    data['createdUserID'] = createdUserID;
    data['lastUpdate'] = lastUpdate?.toIso8601String();
    data['creationDate'] = creationDate?.toIso8601String();
    return data;
  }

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE tasks (
        locId INTEGER PRIMARY KEY AUTOINCREMENT,
        taskID INTEGER UNIQUE,
        projectID INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        deadline TEXT,
        priority TEXT DEFAULT 'Media' CHECK(priority IN ('Baja', 'Media', 'Alta')),
        status TEXT DEFAULT 'Pendiente' CHECK(status IN ('Pendiente', 'En Proceso', 'Completada')),
        createdUserID INTEGER,
        lastUpdate TEXT,
        creationDate TEXT,
        FOREIGN KEY (projectID) REFERENCES project(locId) ON DELETE CASCADE,
        FOREIGN KEY (createdUserID) REFERENCES user(locId) ON DELETE CASCADE
      );
    ''');
  }
}
