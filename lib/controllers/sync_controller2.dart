// import 'package:get/get.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:taskermg/controllers/activitylogController.dart';
// import 'package:taskermg/controllers/project_controller.dart';
// import 'package:taskermg/controllers/task_controller.dart';
// import 'package:taskermg/db/db_local.dart';
// import 'package:taskermg/db/db_helper.dart';
// import 'package:taskermg/models/dbRelations.dart';
// import 'package:taskermg/models/task.dart';
// import 'package:taskermg/models/project.dart';
// import 'package:taskermg/models/activity_log.dart';

// import '../utils/AppLog.dart';
// import 'dbRelationscontroller.dart';

// class SyncController extends GetxController {
//   Future<void> syncData() async {
//     await syncLocaltoRemote();
//   }

//   Future<void> syncProjects(int userID) async {
//     try {
//       var result = await DBHelper.query('''SELECT 
//           p.projectID, 
//           p.name, 
//           p.description, 
//           p.deadline, 
//           p.creationDate, 
//           p.lastUpdate 
//         FROM 
//           project p
//         JOIN 
//           userProject up ON p.projectID = up.projectID
//         JOIN 
//           user u ON up.userID = u.userID
//         WHERE 
//           u.userID = ?''', [userID]);

//       for (var projectMap in result) {
//         Project project = Project(
//             projectID: projectMap['projectID'],
//             name: projectMap['name'],
//             description: projectMap['description'].toString(),
//             deadline: DateTime.tryParse(projectMap['deadline'].toString()),
//             creationDate:
//                 DateTime.tryParse(projectMap['creationDate'].toString()),
//             lastUpdate: DateTime.tryParse(projectMap['lastUpdate'].toString()));

//         //check if is not in local
//         var localProject = await LocalDB.db.query('project',
//             where: 'projectID = ?', whereArgs: [project.projectID]);

//         if (localProject.isNotEmpty) {
//           var localLastUp =
//               DateTime.parse(localProject.first['lastUpdate'].toString());
//           //check is outdated
//           if (project.lastUpdate! != localLastUp) {
//             if (localLastUp.isBefore(project.lastUpdate!)) {
//               AppLog.d("Project ${project.projectID} local data is outdated, updating.");
//                await LocalDB.db.rawUpdate(
//                   'UPDATE project SET name = ?, description = ?, deadline = ?, lastUpdate = ? WHERE projectID = ?',
//                   [project.name, project.description, project.deadline?.toIso8601String(), project.lastUpdate?.toIso8601String(), project.projectID]);
//               AppLog.d("Project ${project.projectID} updated with data $projectMap");
//               continue;
//             }
//             else
//             {
//               //update project in local
//               AppLog.d("Project ${project.projectID} remote data is outdated, skipping.");
//             }
//           } else {
//             AppLog.d("Project ${project.projectID} is up to date, skipping.");
//             continue;
//           }
//         }

//         var map = Project.toMapStatic(project);
//         var res = await LocalDB.db.insert('project', map,
//             conflictAlgorithm: ConflictAlgorithm.replace);

//         AppLog.d("Project inserted with id: $res with data $projectMap");
//       }
//       AppLog.d("project synchronized successfully.");
//     } catch (e) {
//       AppLog.e("Error synchronizing project: $e");
//     }
//   }

//   Future<void> syncTasks(int userID) async {
//     try {
//       var result = await DBHelper.query('''SELECT 
//           t.taskID, 
//           t.projectID, 
//           t.title, 
//           t.description, 
//           t.deadline, 
//           t.priority, 
//           t.status, 
//           t.creationDate, 
//           t.lastUpdate 
//         FROM 
//           tasks t
//         JOIN 
//           project p ON t.projectID = p.projectID
//         JOIN 
//           userProject up ON p.projectID = up.projectID
//         JOIN 
//           user u ON up.userID = u.userID
//         WHERE 
//           u.userID = ?''', [userID]);

//       for (var taskMap in result) {
//         Task task = Task(
//             taskID: taskMap['taskID'],
//             projectID: taskMap['projectID'],
//             title: taskMap['title'],
//             description: taskMap['description'].toString(),
//             deadline: taskMap['deadline'],
//             priority: taskMap['priority'],
//             status: taskMap['status'],
//             creationDate: DateTime.tryParse(taskMap['creationDate'].toString()),
//             lastUpdate: DateTime.tryParse(taskMap['lastUpdate'].toString()));
//         //check if is not in local
//         var localTask = await LocalDB.db
//             .query('tasks', where: 'taskID = ?', whereArgs: [task.taskID]);
        
//         if (localTask.isNotEmpty) {
//           var localLastUp =
//             DateTime.parse(localTask.first['lastUpdate'].toString());
//           //check is outdated
//           if (task.lastUpdate! != localLastUp) {
//             if (localLastUp.isBefore(task.lastUpdate!)) {
//               AppLog.d("Task ${task.taskID} local data is outdated, updating.");
//               await LocalDB.db.rawUpdate(
//                   'UPDATE tasks SET projectID = ?, title = ?, description = ?, status = ?, deadline = ?, lastUpdate = ? WHERE taskID = ?',
//                   [task.projectID, task.title, task.description, task.status, task.deadline?.toIso8601String(), task.lastUpdate?.toIso8601String(), task.taskID]
//               );
//               AppLog.d("Task ${task.taskID} updated with data $taskMap");
//               continue;
//             }
//             else 
//             {
//               AppLog.d("Task ${task.taskID} remote data is outdated, skipping.");
//               continue;
//             }
//           } else {
//             AppLog.d("Task ${task.taskID} is up to date, skipping.");
//             continue;
//           }
//         }

//         var res = await LocalDB.db.insert('tasks', Task.toMapStatic(task),
//             conflictAlgorithm: ConflictAlgorithm.replace);
//         AppLog.d("Task inserted with id: $res with data $taskMap");
//       }
//       AppLog.d("Tasks synchronized successfully.");
//     } catch (e) {
//       AppLog.e("Error synchronizing tasks: $e");
//     }
//   }

//   Future<void> syncRelations(int userID) async {
//     try {
//       var result = await DBHelper.query('''SELECT *
//         FROM 
//           userProject 
//         WHERE 
//           userID = ?''', [userID]);

//       for (var userProjectMap in result) {
//         UserProject userProject = UserProject(
//           userProjectID: userProjectMap['userProjectID'],
//           userID: userProjectMap['userID'],
//           projectID: userProjectMap['projectID'],
//         );
//         //check if not in local
//         var localUserProject = await LocalDB.db.rawQuery(
//             'SELECT * FROM userProject WHERE userProjectID = ?', [userProject.userProjectID]);
//         if (localUserProject.isNotEmpty) {
//           AppLog.d("UserProject is already in local, skipping.");
//           continue;
//         }

//         var res = await LocalDB.db.rawInsert(
//             'INSERT INTO userProject (userProjectID, userID, projectID) VALUES (?, ?, ?)',
//             [userProject.userProjectID,userProject.userID, userProject.projectID]);
//         AppLog.d(
//             "UserProject inserted with id: $res with data $userProjectMap");
//       }
//       AppLog.d("Userproject synchronized successfully.");
//     } catch (e) {
//       AppLog.e("Error synchronizing userproject: $e");
//     }
//   }

//   Future<void> syncLocaltoRemote() async {
//     List<Map<String, dynamic>> unsyncedActivityLogs =
//         await LocalDB.queryUnsyncedActivityLogs();
//     for (var activityLogMap in unsyncedActivityLogs) {
//       ActivityLog activityLog = ActivityLog.fromJson(activityLogMap);
//       AppLog.d("Processing activity log: ${activityLog.toJson()}");
//       //Verificar si la fecha es superior que el activityLog en linea si su activityLogId no es nula
//       if (activityLog.activityID != null) {
//         var result = await DBHelper.query('''SELECT 
//             lastUpdate 
//           FROM 
//             activityLog 
//           WHERE 
//             activityID = ?''', [activityLog.activityID]);
//         if (result.isNotEmpty) {
//           DateTime remotelastUpdate = result.first['lastUpdate'];
//           if (activityLog.lastUpdate! != remotelastUpdate) {
//             if (activityLog.lastUpdate!.isBefore(remotelastUpdate) ||
//                 activityLog.lastUpdate!.isAtSameMomentAs(remotelastUpdate)) {
//               AppLog.d("Activity log is outdated, skipping.");
//               await LocalDB.updateActivityLogSyncStatus(
//                   activityLog.activityID!, true);
//               continue;
//             }
//           } else {
//             AppLog.d("Activity log is up to date, skipping.");
//             await LocalDB.updateActivityLogSyncStatus(
//                 activityLog.activityID!, true);
//             continue;
//           }
//         }
//       }
//       try {
//         if (activityLog.activityType == 'create') {
//           dynamic remoteId;
//           switch (activityLog.activityDetails!['table']) {
//             case 'project':
//               Project project = await LocalDB.db.query("project",
//                   where: 'locId = ?',
//                   whereArgs: [
//                     activityLog.activityDetails!['locId']
//                   ]).then((value) => Project.fromJson(value.first));
//               var query =
//                   'INSERT INTO project (name, description, deadline) VALUES (?, ?, ?)';
//               remoteId = await DBHelper.query(query, [
//                 project.name,
//                 project.description,
//                 project.deadline?.toIso8601String()
//               ]);
//               //update projectID in local
//               LocalDB.updateProjectSyncStatus(project.locId!, remoteId.insertId!);
//               break;
//             case 'tasks':
//               Task task = await LocalDB.db.query("tasks",
//                   where: 'locId = ?',
//                   whereArgs: [
//                     activityLog.activityDetails!['locId']
//                   ]).then((value) => Task.fromJson(value.first));
//               var query =
//                   'INSERT INTO tasks (title, description, status, deadline) VALUES (?, ?, ?, ?)';
//               remoteId = await DBHelper.query(query, [
//                 task.title,
//                 task.description,
//                 task.status,
//                 task.deadline?.toIso8601String()
//               ]);
//               //update taskID in local
//               await LocalDB.updateTaskSyncStatus(task.locId!, remoteId.insertId!);
//               break;
//             case 'userProject':
//               AppLog.d("UserProject activity log");
//               var allrelations = await DbRelationsCtr.getUserProjects();
//               AppLog.d("All relations: $allrelations");

//               UserProject userProject = await LocalDB.db.query("userProject",
//                   where: 'locId = ?',
//                   whereArgs: [
//                     activityLog.activityDetails!['locId']
//                   ]).then((value) => UserProject.fromJson(value.first));

//               //get remote info
//               //objtener projectid del projecto con locid
//               AppLog.d("Getting projectid from local db");
//               int? projectID;
//               var projectResult = await LocalDB.db.query("project",
//                   where: 'locId = ?', whereArgs: [userProject.projectID]);
//               projectID = projectResult.first['projectID'] as int?;
//               AppLog.d("ProjectID: $projectID");
//               //objtener userid del usuario con locid
//               AppLog.d("Getting userid from local db");
//               int? userID;
//               var userResult = await LocalDB.db.query("user",
//                   where: 'locId = ?', whereArgs: [userProject.userID]);
//               userID = userResult.first['userID'] as int?;
//               AppLog.d("UserID: $userID");
//               //insertar en la base de datos remota
//               AppLog.d("Inserting userProject in remote db");
//               var query =
//                   'INSERT INTO userProject (userID, projectID) VALUES (?, ?)';
//               remoteId = await DBHelper.query(query, [userID, projectID]);
            
//               //update projectID in local
//               await DbRelationsCtr.updateUserProjectID(
//                   userProject.locId!, remoteId.insertId!);

//               break;
//           }

//           await LocalDB.updateActivityLogSyncStatus(
//               activityLog.activityID == null
//                   ? activityLog.locId!
//                   : activityLog.activityID!,
//               true);

//           //subir activityLog a la base de datos remota
//           await uploadActLog(activityLog);
//         } else if (activityLog.activityType == 'update') {
//           if (activityLog.activityDetails!['table'] == 'project') {
//             Project project = await LocalDB.db.query("project",
//                 where: 'locId = ?',
//                 whereArgs: [
//                   activityLog.activityDetails!['locId']
//                 ]).then((value) => Project.fromJson(value.first));
//             await DBHelper.query(
//                 'UPDATE project SET name = ?, description = ?, deadline = ? WHERE projectID = ?',
//                 [
//                   project.name,
//                   project.description,
//                   project.deadline?.toIso8601String(),
//                   project.projectID
//                 ]);
//           } else if (activityLog.activityDetails!['table'] == 'tasks') {
//             Task task = await LocalDB.db.query("tasks",
//                 where: 'locId = ?',
//                 whereArgs: [
//                   activityLog.activityDetails!['locId']
//                 ]).then((value) => Task.fromJson(value.first));
//             await DBHelper.query(
//                 'UPDATE tasks SET title = ?, description = ?, status = ?, deadline = ? WHERE id = ?',
//                 [
//                   task.title,
//                   task.description,
//                   task.status,
//                   task.deadline?.toIso8601String(),
//                   task.taskID
//                 ]);
//           }
//           await LocalDB.updateActivityLogSyncStatus(
//               activityLog.activityID == null
//                   ? activityLog.locId!
//                   : activityLog.activityID!,
//               true);
//         } else if (activityLog.activityType == 'delete') {
//           await DBHelper.query(
//               'DELETE FROM ${activityLog.activityDetails!['table']} WHERE id = ?',
//               [activityLog.activityDetails!['id']]);
//           await LocalDB.updateActivityLogSyncStatus(
//               activityLog.activityID == null
//                   ? activityLog.locId!
//                   : activityLog.activityID!,
//               true);
//         }
//       } catch (e) {
//         AppLog.e("Error processing activity log: $e");
//       }
//     }
//   }

//   uploadActLog(ActivityLog activityLog) async {
//     try {
//       var query =
//           'INSERT INTO activityLog (activityType, activityDetails, lastUpdate) VALUES (?, ?, ?)';
//       var res = await DBHelper.query(query, [
//         activityLog.activityType,
//         activityLog.activityDetails.toString(),
//         activityLog.lastUpdate?.toIso8601String()
//       ]);
//       //actualizar id de activityLog en local
//       activityLog.activityID = res.insertId;
//       ActivityLogController.updateAcLog(activityLog);
//     } catch (e) {
//       AppLog.e("Error uploading activity log: $e");
//     }
//   }
// }
