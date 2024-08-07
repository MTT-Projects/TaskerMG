// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/sync_controller.dart';
import 'package:taskermg/common/theme.dart';

class SyncIndicator extends StatelessWidget {
  final SyncController syncController = Get.find();
  var isOffline = MainController.getVar('isOffline');
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return AnimatedPositioned(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        top: 100,
        left: syncController.isSyncing.value
            ? 0
            : -100, // Adjust for exit animation
        child: Container(
          padding: EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            border: Border.all(
              color: AppColors.primaryColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
          ),
          child: isOffline
              ? Icon(
                  Icons.signal_wifi_off,
                  color: Colors.red,
                  size: 35,
                )
              : Lottie.asset(
                  'Assets/lotties/syncIcon.json',
                  width: 35,
                  height: 35,
                ),
        ),
      );
    });
  }
}
