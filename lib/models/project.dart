import 'package:sqflite/sqflite.dart';
import '../utils/AppLog.dart';

class Project {
  int? projectID;
  String? name;
  String? description;
  DateTime? deadline;
  int? proprietaryID;
  DateTime? creationDate;
  DateTime? lastUpdate;

  Project({
    this.projectID,
    this.name,
    this.description,
    this.deadline,
    this.proprietaryID,
    this.creationDate,
    this.lastUpdate,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        projectID: json['projectID'],
        name: json['name'],
        description: json['description'],
        deadline: DateTime.parse(json['deadline']),
        proprietaryID: json['proprietaryID'],
        creationDate: DateTime.parse(json['creationDate']),
        lastUpdate: DateTime.parse(json['lastUpdate']),
      );

  Map<String, dynamic> toJson() => {
        'projectID': projectID,
        'name': name,
        'description': description,
        'deadline': deadline?.toIso8601String(),
        'proprietaryID': proprietaryID,
        'creationDate': creationDate?.toIso8601String(),
        'lastUpdate': lastUpdate?.toIso8601String(),
      };

  static Future<void> createTable(Database db) async {
    await db.execute('''
    crete 
    ''');
    AppLog.d("Table Project created");
  }
}
