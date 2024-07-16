import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:taskermg/utils/sync/sync_projects.dart';
import 'package:taskermg/utils/sync/sync_tasks.dart';
import 'package:taskermg/utils/sync/sync_user_projects.dart';
import 'package:taskermg/utils/AppLog.dart';
class SyncController extends GetxController {
  var isSyncing = false.obs;
  late Timer _syncTimer;

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

  Future<void> _syncData() async {
    AppLog.d("Syncing data...");
    isSyncing.value = true;
    //esperar 5 segundos
    await pullData();
    await pushData();
    await Future.delayed(Duration(seconds: 5));
    isSyncing.value = false;
    AppLog.d("Data synced");
  }

  static Future<void> pullData() async {
    await SyncProjects.pullProjects();
    await SyncTasks.pullTasks();
    await SyncUserProjects.pullUserProjects();
  }

  static Future<void> pushData() async {
    await SyncProjects.pushProjects();
    await SyncTasks.pushTasks();
    await SyncUserProjects.pushUserProjects();
  }
}
