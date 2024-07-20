import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:taskermg/common/dashboard.dart';
import 'package:taskermg/common/projects_page.dart';
import 'package:taskermg/controllers/conecctionChecker.dart';
import 'package:taskermg/utils/sync/sync_attatchments.dart';
import 'package:taskermg/utils/sync/sync_projects.dart';
import 'package:taskermg/utils/sync/sync_taskComment.dart';
import 'package:taskermg/utils/sync/sync_task_assignment.dart';
import 'package:taskermg/utils/sync/sync_tasks.dart';
import 'package:taskermg/utils/sync/sync_user_projects.dart';
import 'package:taskermg/utils/AppLog.dart';
class SyncController extends GetxController {
  var isSyncing = false.obs;
  late Timer _syncTimer;
  bool canSync = true;

  @override
  void onInit() {
    super.onInit();
    // Start the sync timer
    _syncTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _syncData();
    });
  }

  @override
  void onClose() {
    _syncTimer.cancel();
    super.onClose();
  }

  Future<void> fetchAndSyncData()
  async {
    await _syncData();
    ProjectPage.projectController.getProjects();
  }

  void switchCanSync(){
    canSync = !canSync;
  }

  Future<void> _syncData() async {
    if(!canSync)
    {
      AppLog.d("Syncing is disabled");
      return;
    }

    if(await ConnectionChecker.checkConnection() == false)
    {
      AppLog.d("No internet connection, skipping sync");
      return;
    }

    AppLog.d("Syncing data...");
    isSyncing.value = true;
    //esperar 5 segundos
    await pullData();
    await pushData();
    await Future.delayed(Duration(seconds: 2));
    isSyncing.value = false;
    AppLog.d("Data synced");
  }

  static Future<void> pullData() async {
    await SyncProjects.pullProjects();
    await SyncTasks.pullTasks();
    await SyncUserProjects.pullUserProjects();
    await SyncTaskAssignment.pullTaskAssignments();
    await SyncTaskComment.pullTaskComments();
    await SyncAttachment.pullAttachments();
  }

  static Future<void> pushData() async {
    await SyncProjects.pushProjects();
    await SyncTasks.pushTasks();
    await SyncUserProjects.pushUserProjects();
    await SyncTaskAssignment.pushTaskAssignments();
    await SyncTaskComment.pushTaskComments();
    await SyncAttachment.pushAttachments();
  }
}
