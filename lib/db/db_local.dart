import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:taskermg/controllers/dbRelationscontroller.dart';
import 'package:taskermg/controllers/project_controller.dart';
import 'package:taskermg/controllers/taskCommentController.dart';
import 'package:taskermg/controllers/task_controller.dart';
import 'package:taskermg/models/attachment.dart';
import 'package:taskermg/models/taskComment.dart';
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
  static const String _profileDataTable = "profileData";
  static const String _taskCommentTable = "taskComment";
  static const String _attachmentTable = "attachment";
  static const String _taskAttachmentTable = "taskAttachment";
  static const String _taskAssignmentTable = "taskAssignment";
  static const String _projectGoalTable = "projectGoal";

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
        await createTables();
        // Create other tables here
        AppLog.d("Database initialized");
      });
    } catch (e) {
      AppLog.e(e.toString());
    }
    MainController.setVar('initLDB', true);
    return _db;
  }

  static Future<void> createTables() async {
    await User.createTable(db);
    await Project.createTable(db);
    await ProjectGoal.createTable(db);
    await Task.createTable(db);
    await ActivityLog.createTable(db);
    await UserProject.createTable(db);
    await ProfileData.createTable(db);
    await TaskComment.createTable(db);
    await TaskAttachment.createTable(db);
    await TaskAssigment.createTable(db);
    await Attachment.createTable(db);
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

   // Delete functions for all tables

  static Future<void> dropDB() async {
    try {
      //drop all tables
      await _db!.execute('DROP TABLE IF EXISTS $_taskTable');
      await _db!.execute('DROP TABLE IF EXISTS $_projectTable');
      await _db!.execute('DROP TABLE IF EXISTS $_activityLogTable');
      await _db!.execute('DROP TABLE IF EXISTS $_userTable');
      await _db!.execute('DROP TABLE IF EXISTS $_userProjectTable');
      await _db!.execute('DROP TABLE IF EXISTS $_profileDataTable');
      await _db!.execute('DROP TABLE IF EXISTS $_taskCommentTable');
      await _db!.execute('DROP TABLE IF EXISTS $_attachmentTable');
      await _db!.execute('DROP TABLE IF EXISTS $_taskAttachmentTable');
      await _db!.execute('DROP TABLE IF EXISTS $_taskAssignmentTable');
      await _db!.execute('DROP TABLE IF EXISTS $_projectGoalTable');
      //create tables again
      await createTables();
    } catch (e) {
      print("Error deleting database file: $e");
    }
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

  static Future<List<Map<String, dynamic>>> queryUserProjects() async {
    AppLog.d("Query user projects called");
    return await _db!.query(_userProjectTable);
  }

  static Future<List<Map<String, dynamic>>> queryActivityLogs() async {
    AppLog.d("Query activity logs called");
    return await _db!.query(_activityLogTable);
  }

  static Future<List<Map<String, dynamic>>> queryUsers() async {
    AppLog.d("Query users called");
    return await _db!.query(_userTable);
  }

  static Future<List<Map<String, dynamic>>> queryProfileData() async {
    AppLog.d("Query profile data called");
    return await _db!.query(_profileDataTable);
  }

  static Future<List<Map<String, dynamic>>> queryTaskComments() async {
    AppLog.d("Query task comments called");
    return await _db!.query(_taskCommentTable);
  }

  static Future<List<Map<String, dynamic>>> queryAttachments() async {
    AppLog.d("Query attachments called");
    return await _db!.query(_attachmentTable);
  }

  static Future<List<Map<String, dynamic>>> queryTaskAttachments() async {
    AppLog.d("Query task attachments called");
    return await _db!.query(_taskAttachmentTable);
  }

  static Future<List<Map<String, dynamic>>> queryTaskAssignments() async {
    AppLog.d("Query task assignments called");
    return await _db!.query(_taskAssignmentTable);
  }

  static Future<List<Map<String, dynamic>>> queryProjectGoals() async {
    AppLog.d("Query project goals called");
    return await _db!.query(_projectGoalTable);
  }


  // update sync status 

  static Future<int> updateProjectSyncStatus(int locId, int projectId) async {
    //cambiar projectID de la relacion userProject
    var userProjects = await _db!
        .query('userProject', where: 'projectID = ?', whereArgs: [locId]);
    for (var userProject in userProjects) {
      var locId = userProject['locId'] as int;
      if (locId == -1) {
        continue;
      }
      //update userProject projectID
      await DbRelationsCtr.updateProjectID(_userProjectTable,locId, projectId);
    }

    //cambiar projectID de la relacion tasks
    var tasks =
        await _db!.query('tasks', where: 'projectID = ?', whereArgs: [locId]);
    for (var task in tasks) {
      var locId = task['locId'] as int;
      if (locId == -1) {
        continue;
      }
      await TaskController.updateProjectID(locId, projectId);
    }

    //cambiar projectID de la relacion projectGoal
    var projectGoals = await _db!
        .query('projectGoal', where: 'projectID = ?', whereArgs: [locId]);
    for (var projectGoal in projectGoals) {
      var locId = projectGoal['locId'] as int;
      if (locId == -1) {
        continue;
      }
      await ProjectGoalController.updateProjectID(locId, projectId);
    }

    return await _db!.update(
      'project',
      {'projectID': projectId},
      where: 'locId = ?',
      whereArgs: [locId],
    );
  }

  static Future<int> updateProjectGoalSyncStatus(
      int locId, int projectGoalId) async {
    return await _db!.update(
      'projectGoal',
      {'goalID': projectGoalId},
      where: 'locId = ?',
      whereArgs: [locId],
    );
  }

  static Future<int> updateTaskSyncStatus(int locId, int taskId) async {
    //cambiar taskID de la relacion taskAssignment
    var taskAssignments = await _db!
        .query('taskAssignment', where: 'taskID = ?', whereArgs: [locId]);
    for (var taskAssignment in taskAssignments) {
      var locId = taskAssignment['locId'] as int;
      if (locId == -1) {
        continue;
      }
      await DbRelationsCtr.updateTaskID(_taskAssignmentTable,locId, taskId);
    }

    //cambiar taskID de la relacion taskComment
    var taskComments = await _db!
        .query('taskComment', where: 'taskID = ?', whereArgs: [locId]);
    for (var taskComment in taskComments) {
      var locId = taskComment['locId'] as int;
      if (locId == -1) {
        continue;
      }
      await TaskCommentController.updateTaskID(locId, taskId);
    }

    return await _db!.update(
      'tasks',
      {'taskID': taskId},
      where: 'locId = ?',
      whereArgs: [locId],
    );
  }

  static Future<int> updateTaskCommentSyncStatus(
      int locId, int taskCommentId) async {
    //cambiar taskCommentID de la relacion taskAttachment
    var taskAttachments = await _db!.query('taskAttachment',
        where: 'taskCommentID = ?', whereArgs: [locId]);
    for (var taskAttachment in taskAttachments) {
      var locId = taskAttachment['locId'] as int;
      if (locId == -1) {
        continue;
      }
      await DbRelationsCtr.updateTaskCommentID(_taskAttachmentTable,locId, taskCommentId);
    }

    return await _db!.update(
      'taskComment',
      {'taskCommentID': taskCommentId},
      where: 'locId = ?',
      whereArgs: [locId],
    );
  }

  static Future<int> updateTaskAttachmentSyncStatus(
      int locId, int taskAttachmentId) async {
    return await _db!.update(
      'taskAttachment',
      {'taskAttachmentID': taskAttachmentId},
      where: 'locId = ?',
      whereArgs: [locId],
    );
  }

  static Future<int> updateTaskAssignmentSyncStatus(
      int locId, int taskAssignmentId) async {
    return await _db!.update(
      'taskAssignment',
      {'taskAssignmentID': taskAssignmentId},
      where: 'locId = ?',
      whereArgs: [locId],
    );
  }

  //update attatchment
  static Future<int> updateAttachmentSyncStatus(
      int locId, int attachmentId) async {
    //cambiar attachmentID de la relacion taskAttachment
    var taskAttachments = await _db!
        .query('taskAttachment', where: 'attachmentID = ?', whereArgs: [locId]);
    for (var taskAttachment in taskAttachments) {
      var locId = taskAttachment['locId'] as int;
      if (locId == -1) {
        continue;
      }
      await DbRelationsCtr.updateAttachmentId(_taskAttachmentTable,locId, attachmentId);
    }

    return await _db!.update(
      'attachment',
      {'attachmentID': attachmentId},
      where: 'locId = ?',
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

  // Query unsynced data

  static Future<List<Map<String, dynamic>>> queryUnsyncedProjects() async {
    return await _db!.query('project', where: 'projectID IS NULL');
  }

  static Future<List<Map<String, dynamic>>> queryUnsyncedTasks() async {
    return await _db!.query('tasks', where: 'taskID IS NULL');
  }

  static Future<List<Map<String, dynamic>>> queryUnsyncedUserProjects() async {
    return await _db!.query('userProject', where: 'userProjectID IS NULL');
  }

  // Query functions for specific tables

  static Future<Map<String, dynamic>?> queryUserByRemoteID(int userId) async {
    var result =
        await _db!.query('user', where: 'userID = ?', whereArgs: [userId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryUserByLocalID(int userId) async {
    var result =
        await _db!.query('user', where: 'locId = ?', whereArgs: [userId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryActivityLogByRemoteID(
      int activityId) async {
    var result = await _db!
        .query('activityLog', where: 'activityID = ?', whereArgs: [activityId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryActivityLogByLocalID(
      int activityId) async {
    var result = await _db!
        .query('activityLog', where: 'locId = ?', whereArgs: [activityId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryAttachmentByRemoteID(
      int attachmentId) async {
    var result = await _db!.query('attachment',
        where: 'attachmentID = ?', whereArgs: [attachmentId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryAttachmentByLocalID(
      int attachmentId) async {
    var result = await _db!
        .query('attachment', where: 'locId = ?', whereArgs: [attachmentId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryTaskAttachmentByRemoteID(
      int taskAttachmentId) async {
    var result = await _db!.query('taskAttachment',
        where: 'taskAttachmentID = ?', whereArgs: [taskAttachmentId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryTaskAttachmentByLocalID(
      int taskAttachmentId) async {
    var result = await _db!.query('taskAttachment',
        where: 'locId = ?', whereArgs: [taskAttachmentId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryTaskAssignmentByRemoteID(
      int taskAssignmentId) async {
    var result = await _db!.query('taskAssignment',
        where: 'assignmentID = ?', whereArgs: [taskAssignmentId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryTaskAssignmentByLocalID(
      int taskAssignmentId) async {
    var result = await _db!.query('taskAssignment',
        where: 'locId = ?', whereArgs: [taskAssignmentId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryTaskCommentByRemoteID(
      int taskCommentId) async {
    var result = await _db!.query('taskComment',
        where: 'taskCommentID = ?', whereArgs: [taskCommentId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryTaskCommentByLocalID(
      int taskCommentId) async {
    var result = await _db!
        .query('taskComment', where: 'locId = ?', whereArgs: [taskCommentId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryProjectGoalByRemoteID(
      int projectGoalId) async {
    var result = await _db!
        .query('projectGoal', where: 'goalID = ?', whereArgs: [projectGoalId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryProjectGoalByLocalID(
      int projectGoalId) async {
    var result = await _db!
        .query('projectGoal', where: 'locId = ?', whereArgs: [projectGoalId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryProfileDataByRemoteID(
      int profileDataId) async {
    var result = await _db!.query('profileData',
        where: 'profileDataID = ?', whereArgs: [profileDataId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryProfileDataByLocalID(
      int profileDataId) async {
    var result = await _db!
        .query('profileData', where: 'locId = ?', whereArgs: [profileDataId]);
    return result.isNotEmpty ? result.first : null;
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
        await _db!.query('project', where: 'locId = ?', whereArgs: [projectId]);

    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryTaskByRemoteID(int taskId) async {
    var result =
        await _db!.query('tasks', where: 'taskID = ?', whereArgs: [taskId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> queryTaskByLocalID(int taskId) async {
    var result =
        await _db!.query('tasks', where: 'locId = ?', whereArgs: [taskId]);
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
    var result = await _db!
        .query('userProject', where: 'locId = ?', whereArgs: [userProjectID]);
    return result.isNotEmpty ? result.first : null;
  }

//insert functions for all tables
  static Future<int> insertActivityLog(ActivityLog activityLog) async {
    AppLog.d("Insert activity log called");
    return await _db!.rawInsert(
          'INSERT INTO activityLog (userID, projectID, activityType, activityDetails, timestamp, lastUpdate) VALUES (?, ?, ?, ?, ?, ?)',
          [
            activityLog.userID,
            activityLog.projectID,
            activityLog.activityType,
            jsonEncode(activityLog.activityDetails),
            activityLog.timestamp?.toIso8601String(),
            activityLog.lastUpdate?.toIso8601String(),
          ],
        );
  }

  static Future<int> insertProject(Project project) async {
    return await _db!.rawInsert(
      'INSERT INTO project (projectID, name, description, deadline, proprietaryID, creationDate, lastUpdate) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        project.projectID,
        project.name,
        project.description,
        project.deadline?.toIso8601String(),
        project.proprietaryID,
        project.creationDate?.toIso8601String(),
        project.lastUpdate?.toIso8601String(),
      ],
    );
  }

  static Future<int> insertTask(Task task) async {
    return await _db!.rawInsert(
      'INSERT INTO tasks (taskID, projectID, title, description, deadline, priority, status, creationDate, lastUpdate, createdUserID) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        task.taskID,
        task.projectID,
        task.title,
        task.description,
        task.deadline?.toIso8601String(),
        task.priority,
        task.status,
        task.creationDate?.toIso8601String(),
        task.lastUpdate?.toIso8601String(),
        task.createdUserID,
      ],
    );
  }

  static Future<int> insertUserProject(UserProject userProject) async {
    return await _db!.rawInsert(
      'INSERT INTO userProject (userProjectID, userID, projectID, lastUpdate) VALUES (?, ?, ?, ?)',
      [
        userProject.userProjectID,
        userProject.userID,
        userProject.projectID,
        userProject.lastUpdate?.toIso8601String(),
      ],
    );
  }

  static Future<int> insertUser(User user) async {
    return await _db!.rawInsert(
      'INSERT INTO user (userID, name, email, password, lastUpdate) VALUES (?, ?, ?, ?, ?)',
      [
        user.userID,
        user.name,
        user.email,
        user.password,
        user.lastUpdate?.toIso8601String(),
      ],
    );
  }

  static Future<int> insertTaskComment(TaskComment taskComment) async {
    return await _db!.rawInsert(
      'INSERT INTO taskComment (taskCommentID, taskID, userID, comment, timestamp, lastUpdate) VALUES (?, ?, ?, ?, ?, ?)',
      [
        taskComment.taskCommentID,
        taskComment.taskID,
        taskComment.userID,
        taskComment.comment,
        taskComment.creationDate?.toIso8601String(),
        taskComment.lastUpdate?.toIso8601String(),
      ],
    );
  }

  static Future<int> insertAttachment(Attachment attachment) async {
    return await _db!.rawInsert(
      'INSERT INTO attachment (attachmentID, userID, name, type, size, fileUrl, localPath, uploadDate, lastUpdate) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        attachment.attachmentID,
        attachment.userID,
        attachment.name,
        attachment.type,
        attachment.size,
        attachment.fileUrl,
        attachment.localPath,
        attachment.uploadDate?.toIso8601String(),
        attachment.lastUpdate?.toIso8601String(),
      ],
    );
  }

  static Future<int> insertTaskAttachment(TaskAttachment taskAttachment) async {
    return await _db!.rawInsert(
      'INSERT INTO taskAttachment (taskAttachmentID, taskCommentID, attachmentID, lastUpdate) VALUES (?, ?, ?, ?)',
      [
        taskAttachment.taskAttachmentID,
        taskAttachment.taskCommentID,
        taskAttachment.attachmentID,
        taskAttachment.lastUpdate?.toIso8601String(),
      ],
    );
  }

  static Future<int> insertTaskAssignment(TaskAssigment taskAssignment) async {
    return await _db!.rawInsert(
      'INSERT INTO taskAssignment (assignmentID, taskID, userID, lastUpdate) VALUES (?, ?, ?, ?)',
      [
        taskAssignment.assignmentID,
        taskAssignment.taskID,
        taskAssignment.userID,
        taskAssignment.lastUpdate?.toIso8601String(),
      ],
    );
  }

  static Future<int> insertProjectGoal(ProjectGoal projectGoal) async {
    return await _db!.rawInsert(
      'INSERT INTO projectGoal (goalID, projectID, goalDescription, isCompleted, lastUpdate) VALUES (?, ?, ?, ?, ?)',
      [
        projectGoal.goalID,
        projectGoal.projectID,
        projectGoal.goalDescription,
        projectGoal.isCompleted,
        projectGoal.lastUpdate?.toIso8601String(),
      ],
    );
  }

  static Future<int> insertProfileData(ProfileData profileData) async {
    return await _db!.rawInsert(
      'INSERT INTO profileData (profileDataID, userID, profilePic, lastUpdate) VALUES (?, ?, ?, ?)',
      [
        profileData.profileDataID,
        profileData.userID,
        profileData.profilePicUrl
      ],
    );
  }

  // Update functions for all tables
  static Future<int> updateActivityLog(ActivityLog activityLog) async {
    return await _db!.update('activityLog', activityLog.toMap(),
        where: 'locId = ?', whereArgs: [activityLog.locId]);
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

  static Future<int> updateUser(User user) async {
    return await _db!.update('user', user.toMap(),
        where: 'userID = ?', whereArgs: [user.userID]);
  }

  static Future<int> updateTaskComment(TaskComment taskComment) async {
    return await _db!.update('taskComment', taskComment.toMap(),
        where: 'taskCommentID = ?', whereArgs: [taskComment.taskCommentID]);
  }

  static Future<int> updateAttachment(Attachment attachment) async {
    return await _db!.update('attachment', attachment.toMap(),
        where: 'attachmentID = ?', whereArgs: [attachment.attachmentID]);
  }

  static Future<int> updateTaskAttachment(TaskAttachment taskAttachment) async {
    return await _db!.update('taskAttachment', taskAttachment.toMap(),
        where: 'taskAttachmentID = ?',
        whereArgs: [taskAttachment.taskAttachmentID]);
  }

  static Future<int> updateTaskAssignment(TaskAssigment taskAssignment) async {
    return await _db!.update('taskAssignment', taskAssignment.toMap(),
        where: 'assignmentID = ?', whereArgs: [taskAssignment.assignmentID]);
  }

  static Future<int> updateProjectGoal(ProjectGoal projectGoal) async {
    return await _db!.update('projectGoal', projectGoal.toMap(),
        where: 'goalID = ?', whereArgs: [projectGoal.goalID]);
  }

  static Future<int> updateProfileData(ProfileData profileData) async {
    return await _db!.update('profileData', profileData.toMap(),
        where: 'profileDataID = ?', whereArgs: [profileData.profileDataID]);
  }

  // Query unsynced updates
  static Future<List<Map<String, dynamic>>> queryUnsyncedUpdates(
      String table) async {
    
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

        if (actDetails['table'] == table) {
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
