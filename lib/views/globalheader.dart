// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taskermg/common/pages/profile.dart';
import 'package:taskermg/common/settings_page.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/sync_controller.dart';
import 'package:taskermg/controllers/user_controller.dart';
import 'package:taskermg/services/theme_services.dart';

AppBar globalheader(bg, title, {icon = Icons.question_answer_rounded}) {
  final SyncController syncController = Get.put(SyncController());
  ThemeServices _themeServices = ThemeServices();
  var profileData = MainController.getVar('profileData');
  return AppBar(
    automaticallyImplyLeading: false,
    elevation: 0,
    backgroundColor: bg,
    title: Text(
      title,
      style: headingStyleInv,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomRight: Radius.circular(30),
      ),
    ),
    actions: [
      MainController.getVar("isOffline")
          ? IconButton(
              icon: Icon(Icons.wifi_off),
              onPressed: () {
                Get.snackbar(
                  'Modo Offline',
                  'Estás en modo offline, por favor revisa tu conexión a internet',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              },
            )
          :
      IconButton(
        icon: Icon(Icons.sync),
        onPressed: () {
          syncController.fetchAndSyncData();
        },
      ),
      GestureDetector(
        onTap: () {
          Get.to(() => const SettingsScr());
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            radius: 24, // Radio de la imagen
            backgroundImage: MainController.getVar("isOffline")
                ? Image(image: AssetImage('Assets/images/profile.png')).image
                : NetworkImage(
                    profileData['profilePicUrl'] ??
                        'https://via.placeholder.com/150',
                  ),
          ),
        ),
      ),
    ],
    iconTheme: IconThemeData(
      color: _themeServices.isDark ? Colors.black : Colors.white,
    ),
  );
}
