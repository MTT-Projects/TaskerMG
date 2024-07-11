import 'dart:convert';

import 'package:get/get_state_manager/src/simple/get_controllers.dart';

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
      timestamp: DateTime.now(),
      lastUpdate: DateTime.now(),
    ));
  }

  //get all userProject
  static Future<String> getUserProjects() async {
    List<Map<String, dynamic>> userProjects = await LocalDB.db.rawQuery('''
      SELECT *
      FROM userProject up
    ''');

    return jsonEncode(userProjects);
  }

  //update user to project
  static Future<void> updateUserProject(UserProject userProject) async {
    await LocalDB.db.update(
      "userProject",
      userProject.toMap(),
      where: 'locId = ?',
      whereArgs: [userProject.locId],
    );
  }

  //delete user to project
  static Future<void> deleteUserProject(int locId) async {
    await LocalDB.db.delete(
      "userProject",
      where: 'locId = ?',
      whereArgs: [locId],
    );
  }

  //update userProjectID
  static Future<void> updateUserProjectID(int locId, int userProjectID) async {
    await LocalDB.db.rawUpdate('''
      UPDATE userProject
      SET userProjectID = ?
      WHERE locId = ?
    ''', [userProjectID, locId]);
  }

}
