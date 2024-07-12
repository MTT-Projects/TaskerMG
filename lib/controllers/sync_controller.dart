import 'package:get/get.dart';
import 'package:taskermg/utils/sync/sync_projects.dart';
import 'package:taskermg/utils/sync/sync_tasks.dart';
import 'package:taskermg/utils/sync/sync_user_projects.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/activity_log.dart';
import 'package:taskermg/utils/AppLog.dart';

class SyncController extends GetxController {
  Future<void> pullData() async {
    await SyncProjects.pullProjects();
    await SyncTasks.pullTasks();
    await SyncUserProjects.pullUserProjects();
  }

  Future<void> pushData() async {
    await SyncProjects.pushProjects();
    await SyncTasks.pushTasks();
    await SyncUserProjects.pushUserProjects();
  }
}
