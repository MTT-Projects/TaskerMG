import 'package:get/get.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/activity_log.dart';
import 'package:taskermg/utils/AppLog.dart';
import '../models/project.dart';
import 'maincontroller.dart';

class ProjectController extends GetxController {
  // ignore: non_constant_identifier_names
  MainController MC = MainController();

  @override
  void onReady() {
    getProjects();
    super.onReady();
  }

  var projectList = <Project>[].obs;

  Future<void> addProject(Project project) async {
    int locId = await LocalDB.insertProject(project);

    // Registrar la actividad
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MC.getVar('userID'),
      projectID: locId,
      activityType: 'create',
      activityDetails: {
        'table': 'projects',
        'loc_id': locId,
      },
      timestamp: DateTime.now(),
      lastUpdate: DateTime.now(),
    ));
    AppLog.d("Project added with loc_id: $locId");
  }

  void getProjects() async {
    AppLog.d("Getting projects for User: ${MC.getVar('userID')}");
    final userID = MC.getVar('userID');

    if (userID != null) {
      List<Map<String, dynamic>> projects = await LocalDB.db.query(
          "projects",
          where: 'proprietaryID = ?',
          whereArgs: [userID],
      );
      projectList.assignAll(projects.map((data) => Project.fromJson(data)).toList());
    } else {
      projectList.clear(); // Limpiar la lista si no hay un usuario actual seleccionado
    }
  }

  void deleteProject(Project project) async {
    await LocalDB.db.delete(
        "projects", where: 'loc_id = ?', whereArgs: [project.locId]);

    // Registrar la actividad
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MC.getVar('userID'),
      projectID: project.locId,
      activityType: 'delete',
      activityDetails: {
        'table': 'projects',
        'loc_id': project.locId,
      },
      timestamp: DateTime.now(),
      lastUpdate: DateTime.now(),
    ));
    getProjects();
  }

  void updateProject(Project project) async {
    await LocalDB.db.update(
        "projects",
        project.toMap(),
        where: 'loc_id = ?',
        whereArgs: [project.locId],
    );

    // Registrar la actividad
    await LocalDB.insertActivityLog(ActivityLog(
      userID: MC.getVar('userID'),
      projectID: project.locId,
      activityType: 'update',
      activityDetails: {
        'table': 'projects',
        'loc_id': project.locId,
      },
      timestamp: DateTime.now(),
      lastUpdate: DateTime.now(),
    ));
    getProjects();
  }
}
