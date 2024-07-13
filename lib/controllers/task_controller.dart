// ignore_for_file: avoid_init_to_null

import 'package:taskermg/controllers/dbRelationscontroller.dart';
import 'package:taskermg/controllers/taskCommentController.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/models/dbRelations.dart';
import 'package:taskermg/models/taskComment.dart';
import 'package:taskermg/utils/AppLog.dart';
import 'package:get/get.dart';

import '../models/task.dart';
import '../models/activity_log.dart';
import '../services/notification_services.dart';
import 'maincontroller.dart';

class TaskController extends GetxController {

  var notifyHelper = NotifyHelper();

  @override
  void onReady() {
    getTasks();
    super.onReady();
  }

  var taskList = <Task>[].obs;

  Future<int> addTask({required Task task}) async {
    int locId = await LocalDB.insertTask(task);

    // Registrar la actividad
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MainController.getVar('userID'),
      projectID: task.projectID,
      activityType: 'create',
      activityDetails: {
        'table': 'tasks',
        'locId': locId,
      },
      timestamp: DateTime.now().toUtc(),
      lastUpdate: DateTime.now().toUtc(),
    ));
    return locId;
  }

  Future<RxList<Task>> getTasks([project]) async {
    AppLog.d("Getting tasks from Project: ${MainController.getVar('currentProject')}");
    final currentProjectID = project ?? MainController.getVar('currentProject');

    if (currentProjectID != null) {
      List<Map<String, dynamic>> tasks = await LocalDB.db.query(
          "tasks",
          where: 'projectID = ?',
          whereArgs: [currentProjectID],
      );
      taskList.assignAll(tasks.map((data) => Task.fromJson(data)).toList());
    } else {
      taskList.clear(); // Limpiar la lista si no hay un proyecto actual seleccionado
    }
    return taskList;
  }

  void markTaskCompleted(Task task){
    task.status = 'Completada';
    task.lastUpdate = DateTime.now().toUtc();
    updateTask(task);    
  }

  static Future<void> deleteTask(Task task) async {
    // Registrar la actividad
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MainController.getVar('userID'),
      projectID: task.projectID,
      activityType: 'delete',
      activityDetails: {
        'table': 'tasks',
        'locId': task.locId,
        'taskID': task.taskID,
      },
      timestamp: DateTime.now().toUtc(),
      lastUpdate: DateTime.now().toUtc(),
    ));

     var comments = await LocalDB.db.query('taskComment', where: 'taskID = ?', whereArgs: [task.taskID ?? task.locId]);
    for (var comment in comments) {
      await TaskCommentController.deleteTaskComment(TaskComment.fromJson(comment));
    }

    // Eliminar asignaciones de tareas relacionadas
    await LocalDB.db.delete('taskAssignment', where: 'taskID = ?', whereArgs: [task.taskID ?? task.locId]);

    // Eliminar la tarea
    await LocalDB.db.delete('tasks', where: 'taskID = ?', whereArgs: [task.locId]);
  }

  //delete tasks by projectID
  void deleteTasksByProjectID(int projectID) async {
    await LocalDB.db.delete(
        "tasks", where: 'projectID = ?', whereArgs: [projectID]);
    getTasks();
  }
  
  Future<void> updateTask(Task task) async {
    await LocalDB.db.update(
        "tasks",
        task.toMap(),
        where: 'locId = ?',
        whereArgs: [task.locId],
    );

    // Registrar la actividad
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MainController.getVar('userID'),
      projectID: task.projectID,
      activityType: 'update',
      activityDetails: {
        'table': 'tasks',
        'locId': task.locId,
        'taskID': task.taskID,
      },
      timestamp: DateTime.now().toUtc(),
      lastUpdate: DateTime.now().toUtc(),
    ));
    getTasks();
  }

  static updateRemoteID(param0, param1) {}

  static deleteTaskRecursively(int task) {}
}
