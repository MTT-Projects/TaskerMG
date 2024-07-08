import 'package:sqflite/sqflite.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../models/user.dart';
import '../models/activity_log.dart';
import '../utils/AppLog.dart';

class LocalDB {
  static Database? _db;
  static final int _version = 1;

  static final String _taskTable = "tasks";
  static final String _projectTable = "projects";
  static final String _activityLogTable = "activityLog";
  // Define other tables here

  static Future<Database?> initDb() async {
    if (_db != null) {
      return _db;
    }
    try {
      String _path = '${await getDatabasesPath()}taskerMG_db.db';
      _db = await openDatabase(_path, version: _version, onCreate: (db, version) async {
        AppLog.d("Creating a new one");
        await Task.createTable(db);  
        await Project.createTable(db);
        await ActivityLog.createTable(db);
        // Create other tables here
        AppLog.d("Database initialized");
      });
    } catch (e) {
      AppLog.e(e.toString());
    }
    return _db;
  }

  static Database get db {
    if (_db != null) {
      return _db!;
    } else {
      initDb();
      return _db!;
    }
  }

  // Insert functions for all tables
  static Future<int> insertTask(Task task) async {
    AppLog.d("Insert task called");
    return await _db?.insert(_taskTable, task.toMap()) ?? 1;
  }

  static Future<int> insertProject(Project project) async {
    AppLog.d("Insert project called");
    return await _db?.insert(_projectTable, project.toMap()) ?? 1;
  }

  static Future<int> insertActivityLog(ActivityLog activityLog) async {
    AppLog.d("Insert activity log called");
    return await _db?.insert(_activityLogTable, activityLog.toMap()) ?? 1;
  }

  // Query functions for all tables
  static Future<List<Map<String, dynamic>>> queryTasks() async {
    AppLog.d("Query tasks called");
    return await _db!.query(_taskTable);
  }

  static Future<List<Map<String, dynamic>>> queryProjects() async {
    AppLog.d("Query projects called");
    return await _db!.query(_projectTable);
  }

  static Future<List<Map<String, dynamic>>> queryActivityLogs() async {
    AppLog.d("Query activity logs called");
    return await _db!.query(_activityLogTable);
  }

  // Query unsynced data
  static Future<List<Map<String, dynamic>>> queryUnsyncedTasks() async {
    AppLog.d("Query unsynced tasks called");
    return await _db!.query(_taskTable, where: 'taskID IS NULL');
  }

  static Future<List<Map<String, dynamic>>> queryUnsyncedProjects() async {
    AppLog.d("Query unsynced projects called");
    return await _db!.query(_projectTable, where: 'projectID IS NULL');
  }

  static Future<List<Map<String, dynamic>>> queryUnsyncedActivityLogs() async {
    AppLog.d("Query unsynced activity logs called");
    return await _db!.query(_activityLogTable, where: 'isSynced = 0');
  }

  // Update sync status
  static Future<int> updateTaskSyncStatus(int locId, int taskId) async {
    return await _db!.update(
      _taskTable,
      {'taskID': taskId},
      where: 'loc_id = ?',
      whereArgs: [locId],
    );
  }

  static Future<int> updateProjectSyncStatus(int locId, int projectId) async {
    return await _db!.update(
      _projectTable,
      {'projectID': projectId},
      where: 'loc_id = ?',
      whereArgs: [locId],
    );
  }

  static Future<int> updateActivityLogSyncStatus(int id, bool isSynced) async {
    return await _db!.update(
      _activityLogTable,
      {'isSynced': isSynced ? 1 : 0},
      where: 'activityID = ?',
      whereArgs: [id],
    );
  }

  
}
