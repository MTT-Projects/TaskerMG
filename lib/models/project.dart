import 'package:sqflite/sqflite.dart';
import '../utils/AppLog.dart';

class Project {
  int? locId;
  int? projectID;
  String? name;
  String? description;
  DateTime? deadline;
  int? proprietaryID;
  DateTime? creationDate;
  DateTime? lastUpdate;

  Project({
    this.locId,
    this.projectID,
    this.name,
    this.description,
    this.deadline,
    required this.proprietaryID,
    this.creationDate,
    this.lastUpdate,
  });

  Map<String, dynamic> toMap() {
    return {
      'locId': locId,
      'projectID': projectID,
      'name': name,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'proprietaryID': proprietaryID,
      'creationDate': creationDate?.toIso8601String(),
      'lastUpdate': lastUpdate?.toIso8601String(),
    };
  }

  //to map static
  static Map<String, dynamic> toMapStatic(Project project) {
    return {
      'locId': project.locId,
      'projectID': project.projectID,
      'name': project.name,
      'description': project.description,
      'deadline': project.deadline?.toIso8601String(),
      'proprietaryID': project.proprietaryID,
      'creationDate': project.creationDate?.toIso8601String(),
      'lastUpdate': project.lastUpdate?.toIso8601String(),
    };
  }

  //to json
  Map<String, dynamic> toJson() => {
        'locId': locId,
        'projectID': projectID,
        'name': name,
        'description': description,
        'deadline': deadline?.toIso8601String(),
        'proprietaryID': proprietaryID,
        'creationDate': creationDate?.toIso8601String(),
        'lastUpdate': lastUpdate?.toIso8601String(),
      };

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      locId: json['locId'],
      projectID: json['projectID'],
      name: json['name'],
      description: json['description'],
      deadline: DateTime.parse(json['deadline']),
      proprietaryID: json['proprietaryID'],
      creationDate: DateTime.parse(json['creationDate']),
      lastUpdate: DateTime.parse(json['lastUpdate']),
    );
  }

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS project (
        locId INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        projectID INTEGER UNIQUE,
        name TEXT NOT NULL,
        description TEXT,
        deadline TEXT,
        proprietaryID INTEGER,
        creationDate TEXT,
        lastUpdate TEXT,
        FOREIGN KEY (proprietaryID) REFERENCES user(userID) ON DELETE CASCADE
      );
    ''');
    AppLog.d("Project Table Created");
  }
 
}

class ProjectGoal {
  int? locId;
  int? goalID;
  int? projectID;
  String? goalDescription;
  bool? isCompleted;
  DateTime? lastUpdate;

  ProjectGoal({
    this.locId,
    this.goalID,
    this.projectID,
    this.goalDescription,
    this.isCompleted,
    this.lastUpdate,
  });

  Map<String, dynamic> toMap() {
    return {
      'locId': locId,
      'goalID': goalID,
      'projectID': projectID,
      'goalDescription': goalDescription,
      'isCompleted': isCompleted,
      'lastUpdate': lastUpdate?.toIso8601String(),
    };
  }

  //to map static
  static Map<String, dynamic> toMapStatic(ProjectGoal projectGoal) {
    return {
      'locId': projectGoal.locId,
      'goalID': projectGoal.goalID,
      'projectID': projectGoal.projectID,
      'goalDescription': projectGoal.goalDescription,
      'isCompleted': projectGoal.isCompleted,
      'lastUpdate': projectGoal.lastUpdate?.toIso8601String(),
    };
  }

  //to json
  Map<String, dynamic> toJson() => {
        'locId': locId,
        'goalID': goalID,
        'projectID': projectID,
        'goalDescription': goalDescription,
        'isCompleted': isCompleted,
        'lastUpdate': lastUpdate?.toIso8601String(),
      };

  factory ProjectGoal.fromJson(Map<String, dynamic> json) {
    return ProjectGoal(
      locId: json['locId'],
      goalID: json['goalID'],
      projectID: json['projectID'],
      goalDescription: json['goalDescription'],
      isCompleted: json['isCompleted'],
      lastUpdate: DateTime.parse(json['lastUpdate']),
    );
  }

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projectGoal (
          locId INT AUTO_INCREMENT PRIMARY KEY,
          goalID INT UNIQUE,
          projectID INT,
          goalDescription TEXT NOT NULL,
          isCompleted BOOLEAN DEFAULT FALSE,
          lastUpdate TEXT,
          FOREIGN KEY (projectID) REFERENCES project(projectID) ON DELETE CASCADE
      );
    ''');
    AppLog.d("Project Goal Table Created");
  }
}
