import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:taskermg/controllers/attatchmentController.dart';
import 'package:taskermg/controllers/dbRelationscontroller.dart';
import 'package:taskermg/controllers/project_controller.dart';
import 'package:taskermg/controllers/sync_controller.dart';
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
  static const String _dbName = 'DB_taskerMG.db';
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
          onCreate: (dba, version) async {
        AppLog.d("Creating a new one");
        await createTables(dba);
      });
      AppLog.d("LocalDatabase initialized");
    } catch (e) {
      AppLog.e(e.toString());
    }
    MainController.setVar('initLDB', true);
    return _db;
  }

  static Future<void> createTables(db) async {
    AppLog.d("Creating tables");
    await User.createTable(db);
    await Project.createTable(db);
    await ProjectGoal.createTable(db);
    await Task.createTable(db);
    await ActivityLog.createTable(db);
    await UserProject.createTable(db);
    await ProfileData.createTable(db);
    await TaskComment.createTable(db);
    await TaskAssignment.createTable(db);
    await Attachment.createTable(db);
    AppLog.d("Tables created");
  }

  static Future<Database> get db async {
    if (_db != null) {
      return _db!;
    } else {
      await initDb();
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

  // Raw query, optional values
  static Future<List<Map<String, dynamic>>> rawQuery(String query,
      [List<dynamic>? values]) async {
    return await _db!.rawQuery(query, values);
  }

  //raw delete query an values
  static Future<int> rawDelete(String query, List<dynamic> values) async {
    return await _db!.rawDelete(query, values);
  }

  //raw insert query an values
  static Future<int> rawInsert(String query, List<dynamic> values) async {
    return await _db!.rawInsert(query, values);
  }

  //raw update query an values
  static Future<int> rawUpdate(String query, List<dynamic> values) async {
    return await _db!.rawUpdate(query, values);
  }

  //query table, where an wherevalues optional
  static Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<dynamic>? whereArgs}) async {
    return await _db!.query(table, where: where, whereArgs: whereArgs);
  }

  //delete
  static Future<int> delete(String table,
      {String? where, List<dynamic>? whereArgs}) async {
    return await _db!.delete(table, where: where, whereArgs: whereArgs);
  }

  //insert
  static Future<int> insert(String table, Map<String, dynamic> values) async {
    return await _db!.insert(table, values);
  }

  //update
  static Future<int> update(String table, Map<String, dynamic> values,
      {String? where, List<dynamic>? whereArgs}) async {
    return await _db!.update(table, values, where: where, whereArgs: whereArgs);
  }

  // Delete functions for all tables

  static Future<void> dropDB() async {
    try {
      //delete db file
      await deleteDatabase('${await getDatabasesPath()}/$_dbName');
      _db = null;
      //recreate db
      await initDb();

    } catch (e) {
      print("Error deleting database file: $e");
    }
  }

  static Future<void> dropAttatchmentsTable() async {
    try {
      await _db!.execute('DROP TABLE IF EXISTS attachment');
      await Attachment.createTable(_db!);
    } catch (e) {
      print("Error deleting attachment table: $e");
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

  //queryProjectGoalsByProjectID
  static Future<List<Map<String, dynamic>>> queryProjectGoalsByProjectID(
      int projectID) async {
    return await _db!.query(_projectGoalTable, where: 'projectID = ?', whereArgs: [projectID]);
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
      await DbRelationsCtr.updateProjectID(_userProjectTable, locId, projectId);
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
      await DbRelationsCtr.updateTaskID(_taskAssignmentTable, locId, taskId);
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
    //cambiar taskCommentID de la relacion attatchment
    var allattachments = await _db!
        .query('attachment', where: 'taskCommentID = ?', whereArgs: [locId]);

    for (var attachment in allattachments) {
      var locId = attachment['locId'] as int;
      if (locId == -1) {
        continue;
      }
    }
    var attachments = await _db!.rawQuery(
        'SELECT * FROM attachment WHERE taskCommentID = ? AND attachmentID IS NULL', [locId]);
    for (var attachment in attachments) {
      var locId = attachment['locId'] as int;
      if (locId == -1) {
        continue;
      }

      await AttachmentController.updateTaskCommentID(locId, taskCommentId);
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

  static Future<int> updateActivityLogSyncStatus(logMap, int insertId) {
    return _db!.update('activityLog', logMap,
        where: 'locId = ?', whereArgs: [insertId]);
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
    var inserted = await _db!.rawInsert(
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
    return inserted;
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
      'INSERT INTO taskComment (taskCommentID, taskID, userID, comment, creationDate, lastUpdate) VALUES (?, ?, ?, ?, ?, ?)',
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
      'INSERT INTO attachment (attachmentID, taskCommentID, userID, name, type, size, fileUrl, localPath, uploadDate, lastUpdate) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        attachment.attachmentID,
        attachment.taskCommentID,
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

  static Future<int> insertTaskAssignment(TaskAssignment taskAssignment) async {
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
    return await _db!.rawUpdate(
      'UPDATE user SET name = ?, email = ?, password = ?, lastUpdate = ? WHERE userID = ?',
      [
        user.name,
        user.email,
        user.password,
        user.lastUpdate?.toIso8601String(),
        user.userID,
      ],
    );
  }

  static Future<int> updateTaskComment(TaskComment taskComment) async {
    return await _db!.update('taskComment', taskComment.toMap(),
        where: 'taskCommentID = ?', whereArgs: [taskComment.taskCommentID]);
  }

  static Future<int> updateAttachment(Attachment attachment) async {
    return await _db!.update('attachment', attachment.toMap(),
        where: 'attachmentID = ?', whereArgs: [attachment.attachmentID]);
  }

  static Future<int> updateTaskAssignment(TaskAssignment taskAssignment) async {
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

  //Query unsynced creations
  static Future<List<Map<String, dynamic>>> queryUnsyncedCreations(
      String table) async {
    var res = await _db!.rawQuery(
      'SELECT * FROM $_activityLogTable WHERE activityType = "create" AND activityID IS NULL AND isSynced = 0',
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

  static Future<List<Map<String, dynamic>>> queryAttachmentsForTask(
      int taskId) async {
    return _db!.query('attachment', where: 'taskID = ?', whereArgs: [taskId]);
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

  //Mark activitylog has visible
  static Future<int> markActivityLogAsVisible(int activityID) async {
    return await _db!.update(
      _activityLogTable,
      {'showLog': 1},
      where: 'locId = ?',
      whereArgs: [activityID],
    );
  }

  static updateActivityLogID(locId, activityLogId) async {
    return await _db!.update(
      _activityLogTable,
      {'activityID': activityLogId},
      where: 'locId = ?',
      whereArgs: [locId],
    );
  }


}
