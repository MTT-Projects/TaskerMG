// ignore_for_file: avoid_init_to_null

import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/utils/AppLog.dart';
import 'package:get/get.dart';

import '../models/task.dart';
import '../models/activity_log.dart';
import '../services/notification_services.dart';
import 'maincontroller.dart';

class TaskController extends GetxController {

  var notifyHelper = NotifyHelper();
  // ignore: non_constant_identifier_names
  MainController MC = MainController();

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
      userID: MC.getVar('userID'),
      projectID: task.projectID,
      activityType: 'create',
      activityDetails: {
        'table': 'tasks',
        'locId': locId,
      },
      timestamp: DateTime.now(),
      lastUpdate: DateTime.now(),
    ));
    return locId;
  }

  Future<RxList<Task>> getTasks([project]) async {
    AppLog.d("Getting tasks from Project: ${MC.getVar('currentProject')}");
    final currentProjectID = project ?? MC.getVar('currentProject');

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
    task.lastUpdate = DateTime.now();
    updateTask(task);

    // Registrar la actividad
    LocalDB.insertActivityLog(ActivityLog(
      userID: MC.getVar('userID'),
      projectID: task.projectID,
      activityType: 'update',
      activityDetails: {
        'table': 'tasks',
        'locId': task.locId,
      },
      timestamp: DateTime.now(),
      lastUpdate: DateTime.now(),
    ));
    
  }

  void deleteTask(Task task) async {
    await LocalDB.db.delete(
        "tasks", where: 'locId = ?', whereArgs: [task.locId]);

    // Registrar la actividad
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MC.getVar('userID'),
      projectID: task.projectID,
      activityType: 'delete',
      activityDetails: {
        'table': 'tasks',
        'locId': task.locId,
      },
      timestamp: DateTime.now(),
      lastUpdate: DateTime.now(),
    ));
    getTasks();
  }

  void updateTask(Task task) async {
    await LocalDB.db.update(
        "tasks",
        task.toMap(),
        where: 'locId = ?',
        whereArgs: [task.locId],
    );

    // Registrar la actividad
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MC.getVar('userID'),
      projectID: task.projectID,
      activityType: 'update',
      activityDetails: {
        'table': 'tasks',
        'locId': task.locId,
      },
      timestamp: DateTime.now(),
      lastUpdate: DateTime.now(),
    ));
    getTasks();
  }

  static updateRemoteID(param0, param1) {}
}
