import 'package:dos/db/db_local.dart';
import 'package:get/get.dart';

import '../models/task.dart';
import 'maincontroller.dart';

class TaskController extends GetxController {
  // ignore: non_constant_identifier_names
  MainController MC = MainController();

  @override
  void onReady() {
    getTasks();
    super.onReady();
  }

  var taskList = <Task>[].obs;

  Future<int> addTask({Task? task}) async {    
    return await LocalDB.db.insert("task", task!.toJson()) ?? 1;
  }

  void getTasks() async {
    // Obtener el ID del proyecto actual desde MainController
    final currentProjectID = MC.getVar('currentProject');

    if (currentProjectID != null) {
      // Realizar consulta con cláusula WHERE para filtrar por ID de proyecto
      List<Map<String, dynamic>> tasks = await LocalDB.db.query("task", where: 'projectID = ?', whereArgs: [currentProjectID]);
      taskList.assignAll(tasks.map((data) => Task.fromJson(data)).toList());
    } else {
      taskList.clear(); // Limpiar la lista si no hay un proyecto actual seleccionado
    }
  }

  void delete(Task task) {
    LocalDB.db.delete("task", where: 'id =? ', whereArgs: [task.id]);
    getTasks();
  }

  void updateTask(Task task) async {
    LocalDB.db.rawUpdate('''
        UPDATE task
        SET status = ?
        WHERE id = ?
    ''', [task.status, task.id]);
    getTasks();
  }
}
