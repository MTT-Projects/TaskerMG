import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/utils/AppLog.dart';
import 'package:get/get.dart';

import '../models/task.dart';
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

  Future<int> addTask({Task? task}) async {
  await DBHelper.query(
      "INSERT INTO tasks (title, description, status, projectID, deadline) VALUES (?, ?, ?, ?, ?)",
      [task!.title, task.description, task.status, task.projectID, task.deadline?.toIso8601String()]);

  return await LocalDB.db.rawInsert(
      "INSERT INTO tasks (title, description, status, projectID, deadline) VALUES (?, ?, ?, ?, ?)",
      [task.title, task.description, task.status, task.projectID, task.deadline?.toIso8601String()]);

      
}

  void getTasks() async {
    AppLog.d("Getting tasks from Project: ${MC.getVar('currentProject')}");
    // Obtener el ID del proyecto actual desde MainController
    final currentProjectID = MC.getVar('currentProject');

    if (currentProjectID != null) {
      // Realizar consulta con cláusula WHERE para filtrar por ID de proyecto
      List<Map<String, dynamic>> tasks = await LocalDB.db
          .query("tasks", where: 'projectID = ?', whereArgs: [currentProjectID]);
      taskList.assignAll(tasks.map((data) => Task.fromJson(data)).toList());
    } else {
      taskList
          .clear(); // Limpiar la lista si no hay un proyecto actual seleccionado
    }
  }

  void delete(Task task) {
    LocalDB.db.delete("tasks", where: 'id =? ', whereArgs: [task.id]);
    getTasks();
  }

  void updateTask(Task task) async {
    LocalDB.db.rawUpdate('''
        UPDATE tasks
        SET status = ?
        WHERE id = ?
    ''', [task.status, task.id]);
    getTasks();
  }
}
