import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
  static const String _dbName = 'taskerMG_db.db';
  static const String _taskTable = "tasks";
  static const String _projectTable = "project";
  static const String _activityLogTable = "activityLog";
  static const String _userTable = "user";
  static const String _userProjectTable = "userProject";
  static LocalDB? instance;

  static Future<Database?> initDb() async {
    if (_db != null) {
      return _db;
    }
    try {
      String _path = '${await getDatabasesPath()}/$_dbName';
      _db = await openDatabase(_path, version: _version,
          onCreate: (db, version) async {
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
    MainController.setVar('initLDB', true);
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
        List<Map<String, dynamic>> result =
            await db.rawQuery('PRAGMA table_info($tableName)');
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

  static Future<int> insertActivityLog(ActivityLog activityLog) async {
    AppLog.d("Insert activity log called");
    return await _db?.insert(
          _activityLogTable,
          activityLog.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        ) ??
        1;
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

  static Future<void> dropDB() async {
    try {
      String dbPath =
          '/data/user/0/com.mttprojects.taskermg/databases/$_dbName';
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

  static Future<int> updateProjectSyncStatus(int locId, int projectId) async {
    //cambiar projectID de la relacion userProject
    var res = _db!.update(
      'userProject',
      {'projectID': projectId},
      where: 'projectID = ?',
      whereArgs: [locId],
    );

    //cambiarprojectID de la relacion tasks
    var res2 = _db!.update(
      'tasks',
      {'projectID': projectId},
      where: 'projectID = ?',
      whereArgs: [locId],
    );

    return await _db!.update(
      'project',
      {'projectID': projectId},
      where: 'locID = ?',
      whereArgs: [locId],
    );
  }

  static Future<int> updateTaskSyncStatus(int locId, int taskId) async {
    return await _db!.update(
      'tasks',
      {'taskID': taskId},
      where: 'locID = ?',
      whereArgs: [locId],
    );
  }

  static Future<int> updateUserProjectSyncStatus(
      int locId, int userProjectId) async {
    return await _db!.update(
      'userProject',
      {'userProjectID': userProjectId},
      where: 'locId = ?',
      whereArgs: [locId],
    );
  }

  static Future<List<Map<String, dynamic>>> queryUnsyncedProjects() async {
    return await _db!.query('project', where: 'projectID IS NULL');
  }

  static Future<List<Map<String, dynamic>>> queryUnsyncedTasks() async {
    return await _db!.query('tasks', where: 'taskID IS NULL');
  }

  static Future<List<Map<String, dynamic>>> queryUnsyncedUserProjects() async {
    return await _db!.query('userProject', where: 'userProjectID IS NULL');
  }

  static Future<Map<String, dynamic>?> queryProjectByRemoteID(
      int projectId) async {
    var result = await _db!
        .query('project', where: 'projectID = ?', whereArgs: [projectId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryProjectByLocalID(
      int projectId) async {
    var result =
        await _db!.query('project', where: 'locID = ?', whereArgs: [projectId]);

    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryTaskByRemoteID(int taskId) async {
    var result =
        await _db!.query('tasks', where: 'taskID = ?', whereArgs: [taskId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryTaskByLocalID(int taskId) async {
    var result =
        await _db!.query('tasks', where: 'locID = ?', whereArgs: [taskId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryUserProjectByRemoteID(
      int userProjectID) async {
    var result = await _db!.query('userProject',
        where: 'userProjectID = ?', whereArgs: [userProjectID]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryUserProjectByLocalID(
      int userProjectID) async {
    var result = await _db!.query('userProject',
        where: 'locID = ?', whereArgs: [userProjectID]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<int> insertProject(Project project) async {
    return await _db!.insert('project', project.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> insertTask(Task task) async {
    return await _db!.insert('tasks', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> insertUserProject(UserProject userProject) async {
    return await _db!.insert('userProject', userProject.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> updateProject(Project project) async {
    return await _db!.update('project', project.toMap(),
        where: 'projectID = ?', whereArgs: [project.projectID]);
  }

  static Future<int> updateTask(Task task) async {
    return await _db!.update('tasks', task.toMap(),
        where: 'taskID = ?', whereArgs: [task.taskID]);
  }

  static Future<int> updateUserProject(UserProject userProject) async {
    return await _db!.update('userProject', userProject.toMap(),
        where: 'userProjectID = ?', whereArgs: [userProject.userProjectID]);
  }

  // Query unsynced updates
  static Future<List<Map<String, dynamic>>> queryUnsyncedUpdates(
      String table) async {
    //show all activities
    var all = await _db!.query(_activityLogTable);
    AppLog.d("All activities: $all");
    var res = await _db!.rawQuery(
      'SELECT * FROM $_activityLogTable WHERE activityType = "update" AND activityID IS NULL AND isSynced = 0',
    );

    if (res.isNotEmpty) {
      List<Map<String, dynamic>> retList = [];
      for (var activity in res) {
        var actDetails = jsonDecode(activity['activityDetails'] as String);
        if (actDetails['table'] == table) {
          retList.add(activity);
        }
      }
      return retList;
    } else {
      return [];
    }
  }

  // Query unsynced deletions
  static Future<List<Map<String, dynamic>>> queryUnsyncedDeletions(
      String table) async {
    var res = await _db!.rawQuery(
      'SELECT * FROM $_activityLogTable WHERE activityType = "delete" AND activityID IS NULL AND isSynced = 0',
    );
    if (res.isNotEmpty) {
      List<Map<String, dynamic>> retList = [];
      for (var activity in res) {
        var actDetails = jsonDecode(activity['activityDetails'] as String);
        if (actDetails['table'] == table && actDetails['projectID'] != null) {
          retList.add(activity);
        }
      }
      return retList;
    } else {
      return [];
    }
  }

  // Query unsynced activity logs
  static Future<List<Map<String, dynamic>>> queryUnsyncedActivityLogs() async {
    return await _db!.query(_activityLogTable, where: 'isSynced = 0');
  }

  // Mark activity log as synced
  static Future<int> markActivityLogAsSynced(int activityID) async {
    return await _db!.update(
      _activityLogTable,
      {'isSynced': 1},
      where: 'locId = ?',
      whereArgs: [activityID],
    );
  }
}
