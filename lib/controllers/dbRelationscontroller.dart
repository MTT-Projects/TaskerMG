import 'dart:convert';

import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:taskermg/models/attachment.dart';

import '../db/db_local.dart';
import '../models/activity_log.dart';
import '../models/dbRelations.dart';
import '../models/project.dart';
import '../utils/AppLog.dart';
import 'maincontroller.dart';

class DbRelationsCtr extends GetxController {
  MainController MC = MainController();

  get projectList => null;

  //set user to project
  static Future<void> addUserProject(userid, projectid) async {
    UserProject userProject = UserProject(
      userID: userid,
      projectID: projectid,
      lastUpdate: DateTime.now().toUtc(),
    );
    var valuelocID = await LocalDB.insertUserProject(userProject);

    AppLog.d("User $valuelocID added to project: $userid, $projectid") ;
    userProject.locId = valuelocID;
    AppLog.d("RelationData: ${userProject.toJson()}") ;

    //guardar activitylog
    await LocalDB.insertActivityLog(ActivityLog(
      userID: userid,
      projectID: projectid,
      activityType: 'create',
      activityDetails: {
        'table': 'userProject',
        'locId': valuelocID,
      },
      timestamp: DateTime.now().toUtc(),
      lastUpdate: DateTime.now().toUtc(),
    ));
  }

  //get all userProject
  static Future<String> getUserProjects() async {
    List<Map<String, dynamic>> userProjects = await LocalDB.rawQuery('''
      SELECT *
      FROM userProject up
    ''',[]);

    return jsonEncode(userProjects);
  }

  //update user to project
  Future<void> updateUserProject(UserProject userProject) async {
    await LocalDB.update(
      "userProject",
      userProject.toMap(),
      where: 'locId = ?',
      whereArgs: [userProject.locId],
    );
  }

  //delete user to project
  static Future<void> deleteUserProject(int locId) async {
    await LocalDB.delete(
      "userProject",
      where: 'locId = ?',
      whereArgs: [locId],
    );
  }

  //update userProjectID
  static Future<void> updateUserProjectID(int locId, int userProjectID) async {
    await LocalDB.rawUpdate('''
      UPDATE userProject
      SET userProjectID = ?
      WHERE locId = ?
    ''', [userProjectID, locId]);
  }
  
  //update projectID
  static Future<void> updateProjectID(String table, int locId, int projectID) async {
    await LocalDB.rawUpdate('''
      UPDATE $table
      SET projectID = ?
      WHERE locId = ?
    ''', [projectID, locId]);
  }

  static deleteTaskAttachment(TaskAttachment taskAttachment) async {
     // Registrar la actividad
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MainController.getVar('userID'),
      projectID: null,
      activityType: 'delete',
      activityDetails: {
        'table': 'taskAttachment',
        'locId': taskAttachment.locId,
        'taskAttachmentID': taskAttachment.taskAttachmentID,
      },
      timestamp: DateTime.now().toUtc(),
      lastUpdate: DateTime.now().toUtc(),
    ));
    
     // Eliminar el adjunto
    var attachment = await LocalDB.query("taskAttachment", where: 'taskAttachmentID = ?', whereArgs: [taskAttachment.taskAttachmentID ?? taskAttachment.locId]);
    if (attachment.isNotEmpty) {
      await LocalDB.delete("attachment", where: 'attachmentID = ?', whereArgs: [attachment.first['attachmentID']]);
    }
    await LocalDB.delete("taskAttachment", where: 'taskAttachmentID = ?', whereArgs: [taskAttachment.locId]);
  }

  static updateTaskID(String table, int locId, int taskId) {
    LocalDB.rawUpdate('''
      UPDATE ?
      SET taskID = ?
      WHERE locId = ?
    ''', [table, taskId, locId]);
  }

  static updateTaskCommentID(String table, int locId, int taskCommentId) {
    LocalDB.rawUpdate('''
      UPDATE ?
      SET taskCommentID = ?
      WHERE locId = ?
    ''', [table, taskCommentId, locId]);
  }

  static updateAttachmentId(String table,int locId, int attachmentId) {
    LocalDB.rawUpdate('''
      UPDATE ?
      SET attachmentID = ?
      WHERE locId = ?
    ''', [table, attachmentId, locId]);
  }

  
  

}
