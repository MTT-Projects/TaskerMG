import 'dart:convert';
import 'package:mysql1/mysql1.dart';
import 'package:taskermg/controllers/conecctionChecker.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/dbRelationscontroller.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/dbRelations.dart';
import 'package:taskermg/utils/AppLog.dart';
import 'package:intl/intl.dart';

class SyncUserProjects {
  static String formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

  static Future<void> pullUserProjects() async {
    var userID = MainController.getVar('currentUser');
    try {
      var result = await DBHelper.query('''
      SELECT 
        up.userProjectID, 
        up.userID, 
        up.projectID, 
        up.lastUpdate
      FROM 
        userProject up
      JOIN 
        project p ON up.projectID = p.projectID
      WHERE 
        up.projectID IN (
          SELECT 
            up_inner.projectID 
          FROM 
            userProject up_inner
          WHERE 
            up_inner.userID = ?
        )
    ''', [userID]);

      var remoteUserProjects = result
          .map((userProjectMap) => userProjectMap['userProjectID'])
          .toList();
      AppLog.d("Proyectosusuario remotos: $remoteUserProjects");
      //fetch local user projects
      var localUserProjects = await LocalDB.queryUserProjects();
      if (localUserProjects.isEmpty) {
        AppLog.d("No hay proyectosusuario locales.");
      } else {
        var localUserProjectIDs = localUserProjects
            .map((userProject) => userProject['userProjectID'])
            .toList();

        // Detect deleted user projects
        for (var localUserProjectID in localUserProjectIDs) {
          if (!remoteUserProjects.contains(localUserProjectID)) {
            await LocalDB.rawDelete(
              "DELETE FROM userProject WHERE userProjectID = ?",
              [localUserProjectID],
            );
            AppLog.d(
                "Proyectousuario con ID $localUserProjectID marcado como eliminado.");
          }
        }
      }

      for (var userProjectMap in result) {
        var userProjectMapped = UserProject(
          locId: userProjectMap['locId'],
          userProjectID: userProjectMap['userProjectID'],
          userID: userProjectMap['userID'],
          projectID: userProjectMap['projectID'],
          lastUpdate: userProjectMap['lastUpdate'],
        ).toJson();
        await handleUserProjectSync(userProjectMapped);
      }
      AppLog.d("Proyectosusuario obtenidos exitosamente.");
    } catch (e) {
      AppLog.e("Error al obtener proyectosusuario: $e");
    }
  }

  static Future<void> pushUserProjects() async {
    if (await ConnectionChecker.checkConnection() == false) {
      AppLog.d("No hay conexión a internet, saltando la sincronización de proyectosusuario");
      return;
    }
    //applog all user projects
    var alluserproject = await LocalDB.queryUserProjects();
    AppLog.d("Proyectosusuario: ${jsonEncode(alluserproject)}");

    try {
      var unsyncedUserProjects =
          await LocalDB.queryUnsyncedCreations('userProject');
      AppLog.d(
          "Proyectosusuario sin sincronizar: ${jsonEncode(unsyncedUserProjects)}");
      for (var actMap in unsyncedUserProjects) {
        var details = jsonDecode(actMap['activityDetails']);

        await handleRemoteUserProjectInsert(actMap);
      }

      var unsyncedUserProjectUpdates =
          await LocalDB.queryUnsyncedUpdates('userProject');
      AppLog.d(
          "Proyectosusuario sin actualizar: ${jsonEncode(unsyncedUserProjectUpdates)}");
      for (var actMap in unsyncedUserProjectUpdates) {
        await handleRemoteUserProjectUpdate(actMap);
      }

      var unsyncedDeletions =
          await LocalDB.queryUnsyncedDeletions('userProject');
      AppLog.d(
          "Proyectosusuario sin eliminar: ${jsonEncode(unsyncedDeletions)}");
      for (var deletion in unsyncedDeletions) {
        await handleRemoteUserProjectDeletion(deletion);
      }

      AppLog.d("Proyectosusuario enviados exitosamente.");
    } catch (e) {
      AppLog.e("Error al enviar proyectosusuario: $e");
    }
  }

  static Future<void> handleUserProjectSync(
      Map<String, dynamic> userProjectMap) async {
    var localUserProject = await LocalDB.queryUserProjectByRemoteID(
        userProjectMap['userProjectID']);
    if (localUserProject == null) {
      await LocalDB.insertUserProject(UserProject.fromJson(userProjectMap));
    } else {
      if (DateTime.parse(userProjectMap['lastUpdate'])
          .isAfter(DateTime.parse(localUserProject['lastUpdate']))) {
        await LocalDB.updateUserProject(UserProject.fromJson(userProjectMap));
      }
    }
  }

  static Future<void> handleRemoteUserProjectInsert(
      Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var userProjectMap = Map<String, dynamic>();
    if (actDetails['userProjectID'] != null) {
      userProjectMap = (await LocalDB.queryUserProjectByRemoteID(
          actDetails['userProjectID']))!;
    } else {
      userProjectMap =
          (await LocalDB.queryUserProjectByLocalID(actDetails['locId']))!;
    }

    String userID = userProjectMap['userID'].toString();
    String projectID = userProjectMap['projectID'].toString();
    String lastUpdate =
        formatDateTime(DateTime.parse(userProjectMap['lastUpdate']));

    var response = await DBHelper.query(
      "INSERT INTO userProject (userID, projectID, lastUpdate) VALUES (?, ?, ?)",
      [userID, projectID, lastUpdate],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);
      var insertId = response.insertId;
      if (insertId != null) {
        await LocalDB.updateUserProjectSyncStatus(
            userProjectMap['locId'], insertId);
      }
    } else {
      AppLog.e("Error inserting user project in remote database: $response");
    }
  }

  static Future<void> handleRemoteUserProjectUpdate(
      Map<String, dynamic> actMap) async {
    var actDetails = jsonDecode(actMap['activityDetails']);
    var userProjectMap = Map<String, dynamic>();
    if (actDetails['userProjectID'] != null) {
      userProjectMap = (await LocalDB.queryUserProjectByRemoteID(
          actDetails['userProjectID']))!;
    } else {
      userProjectMap =
          (await LocalDB.queryUserProjectByLocalID(actDetails['locId']))!;
    }

    String userID = userProjectMap['userID'].toString();
    String projectID = userProjectMap['projectID'].toString();
    String lastUpdate =
        formatDateTime(DateTime.parse(userProjectMap['lastUpdate']));

    var response = await DBHelper.query(
      "UPDATE userProject SET userID = ?, projectID = ?, lastUpdate = ? WHERE userProjectID = ?",
      [userID, projectID, lastUpdate, userProjectMap['userProjectID']],
    );

    if (response is Results) {
      await LocalDB.markActivityLogAsSynced(actMap['locId']);
    } else {
      AppLog.e("Error updating user project in remote database: $response");
    }
  }

  static Future<void> handleRemoteUserProjectDeletion(
      Map<String, dynamic> deletion) async {
    var activityDetails = jsonDecode(deletion['activityDetails']);
    var remoteID = activityDetails['userProjectID'] ?? activityDetails['locId'];
    await DBHelper.query(
      "DELETE FROM userProject WHERE userProjectID = ?",
      [remoteID],
    );
    var delLocId = deletion['locId'];
    await LocalDB.markActivityLogAsSynced(delLocId);
  }
}
