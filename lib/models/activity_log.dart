import 'package:sqflite/sqflite.dart';

class ActivityLog {
  int? locId;
  int? activityID;
  int? userID;
  int? projectID;
  String? activityType;
  Map<String, dynamic>? activityDetails;
  DateTime? timestamp;
  DateTime? lastUpdate;

  ActivityLog({
    this.locId,
    this.activityID,
    this.userID,
    this.projectID,
    this.activityType,
    this.activityDetails,
    this.timestamp,
    this.lastUpdate,
  });

  Map<String, dynamic> toMap() {
    return {
      'loc_id': locId,
      'activityID': activityID,
      'userID': userID,
      'projectID': projectID,
      'activityType': activityType,
      'activityDetails': activityDetails,
      'timestamp': timestamp?.toIso8601String(),
      'lastUpdate': lastUpdate?.toIso8601String(),
    };
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      locId: json['loc_id'],
      activityID: json['activityID'],
      userID: json['userID'],
      projectID: json['projectID'],
      activityType: json['activityType'],
      activityDetails: json['activityDetails'],
      timestamp: DateTime.parse(json['timestamp']),
      lastUpdate: DateTime.parse(json['lastUpdate']),
    );
  }

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE activityLog (
        loc_id INTEGER PRIMARY KEY AUTOINCREMENT,
        activityID INTEGER,
        userID INTEGER,
        projectID INTEGER,
        activityType TEXT,
        activityDetails TEXT,
        timestamp TEXT,
        lastUpdate TEXT
      )
    ''');
  }
}
