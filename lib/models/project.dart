import 'package:sqflite/sqflite.dart';

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
      CREATE TABLE project (
        locId INTEGER PRIMARY KEY AUTOINCREMENT,
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
  }
}
