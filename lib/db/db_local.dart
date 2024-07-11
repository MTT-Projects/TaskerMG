import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../controllers/maincontroller.dart';
import '../models/dbRelations.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../models/user.dart';
import '../models/activity_log.dart';
import '../utils/AppLog.dart';

class LocalDB {
  static Database? _db;
  static const int _version = 1;
  static bool initalized = false;
  static const String _dbName = 'taskerMG_db.db';
  static const String _taskTable = "tasks";
  static const String _projectTable = "project";
  static const String _activityLogTable = "activityLog";
  static const String _userTable = "user";
  static const String _userProjectTable = "userProject";
  static LocalDB? instance;
  static MainController MC = MainController();
  // Define other tables here

  static Future<Database?> initDb() async {
    if (_db != null) {
      return _db;
    }
    try {
      String _path = '${await getDatabasesPath()}/$_dbName';
      _db = await openDatabase(_path, version: _version, onCreate: (db, version) async {
        AppLog.d("Creating a new one");
        await Task.createTable(db);
        await Project.createTable(db);
        await ActivityLog.createTable(db);
        await UserProject.createTable(db);
        await User.createTable(db);
        // Create other tables here
        AppLog.d("Database initialized");
      });
    } catch (e) {
      AppLog.e(e.toString());
    }
    await checkTablesIntegrity();
    MC.setVar('initLDB', true);
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

  static LocalDB? get instanceDB {
    if (instance != null) {
      return instance;
    } else {
      instance = LocalDB();
      return instance;
    }
  }

  static Future<void> checkTablesIntegrity() async {
    AppLog.d("Checking tables integrity");
    final db = LocalDB.db;

    // Define expected table schemas
    Map<String, Future<void> Function(Database)> expectedTables = {
      _taskTable: Task.createTable,
      _projectTable: Project.createTable,
      _activityLogTable: ActivityLog.createTable,
      _userTable: User.createTable,
      _userProjectTable: UserProject.createTable,
      // Add other table create functions here
    };

    // Check and create or update tables
    expectedTables.forEach((tableName, createFunction) async {
      try {
        // Check if table exists
        List<Map<String, dynamic>> result = await db.rawQuery('PRAGMA table_info($tableName)');
        if (result.isEmpty) {
          // Table does not exist, create it
          await createFunction(db);
          AppLog.d("Table $tableName created.");
        } else {
          // Table exists, compare schema
          // TODO: Implement schema comparison and update logic here if necessary
        }
      } catch (e) {
        AppLog.e("Error checking table $tableName: $e");
      }
    });
  }

  // Insert functions for all tables
  static Future<int> insertTask(Task task) async {
    AppLog.d("Insert task called");
    return await _db?.insert(
      _taskTable,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Reemplaza si ya existe
    ) ?? 1;
  }

  static Future<int> insertProject(Project project) async {
    AppLog.d("Insert project called");
    return await _db?.insert(
      _projectTable,
      project.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Reemplaza si ya existe
    ) ?? 1;
  }

  // Insert user
  static Future<int> insertUser(User user) async {
    AppLog.d("Insert user called");
    return await _db?.insert(
      _userTable,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Reemplaza si ya existe
    ) ?? 1;
  }

  // Insert userProject
  static Future<int> insertUserProject(UserProject userProject) async {
    AppLog.d("Insert userProject called");
    return await _db?.rawInsert(
      '''
      INSERT INTO userProject (userID, projectID) VALUES (?, ?)
      ''',
      [userProject.userID, userProject.projectID],
    ) ?? 1;
  }

  static Future<int> insertActivityLog(ActivityLog activityLog) async {
    AppLog.d("Insert activity log called");
    return await _db?.insert(
      _activityLogTable,
      activityLog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Reemplaza si ya existe
    ) ?? 1;
  }

  // Raw query
  static Future<List<Map<String, dynamic>>> rawQuery(String query) async {
    AppLog.d("Raw query called");
    try {
      return await _db!.rawQuery(query);
    } catch (e) {
      AppLog.e("Error in raw query: $e");
      return [];
    }
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
      where: 'locId = ?',
      whereArgs: [locId],
    );
  }

  static Future<int> updateProjectSyncStatus(int locId, int projectId) async {
    return await _db!.update(
      _projectTable,
      {'projectID': projectId},
      where: 'locId = ?',
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

  static Future<void> dropDB() async {
    try {
      String dbPath = '/data/user/0/com.mttprojects.taskermg/databases/$_dbName';
      final file = File(dbPath);
      if (await file.exists()) {
        await file.delete();
        _db = null; // Reset the database instance
        print("Database file deleted successfully.");
      } else {
        print("Database file does not exist.");
      }
    } catch (e) {
      print("Error deleting database file: $e");
    }
  }
}
