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
    this.proprietaryID,
    this.creationDate,
    this.lastUpdate,
  });

  Map<String, dynamic> toMap() {
    return {
      'loc_id': locId,
      'projectID': projectID,
      'name': name,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'proprietaryID': proprietaryID,
      'creationDate': creationDate?.toIso8601String(),
      'lastUpdate': lastUpdate?.toIso8601String(),
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      locId: json['loc_id'],
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
      CREATE TABLE projects (
        loc_id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectID INTEGER,
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
