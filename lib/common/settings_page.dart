import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:googleapis/admob/v1.dart';
import 'package:taskermg/api/firebase_api.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/common/widgets/splash.dart';
import 'package:taskermg/controllers/sync_controller.dart';
import 'package:taskermg/controllers/user_controller.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/services/AuthService.dart';
import 'package:taskermg/services/theme_services.dart';
import 'package:taskermg/utils/AppLog.dart';

import '../auth/login.dart';

class SettingsScr extends StatefulWidget {
  const SettingsScr({super.key});

  @override
  State<SettingsScr> createState() => _SettingsScrState();
}

class _SettingsScrState extends State<SettingsScr> {
  final ThemeServices _themeController = Get.put(ThemeServices());
  bool _giveVerse = ThemeServices().isDark; // Define the _giveVerse variable
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
      //switch para cambiar el tema del sistema
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //Delete DB
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Delete DB', style: titleStyle),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    AppLog.d('Delete DB task started');
                    await LocalDB.dropDB();
                    Get.snackbar('DB Deleted', 'DB has been deleted');
                    //reiniciar la app
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const Splash()));
                  },
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Dark Mode', style: titleStyle),
                CupertinoSwitch(
                  value: _giveVerse,
                  onChanged: (bool value) {
                    //cambiar el tema del sistema
                    _themeController.switchTheme();
                    setState(() {
                      _giveVerse = value;
                    });
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const Splash()));
                  },
                )
              ],
            ),
            //Logout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Logout', style: titleStyle),
                TextButton(
                    onPressed: () async {
                      AppLog.d('Logout task started');
                      await AuthService.logout();
                      //delete db
                      await LocalDB.dropDB();
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => const LoginScreen()));
                    },
                    child: const Text(
                      "LogOut",
                      style: TextStyle(color: Colors.white),
                    ))
              ],
            ),
            //SynctoCloud
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Sync to Cloud', style: titleStyle),
                IconButton(
                  icon: Icon(Icons.cloud_upload),
                  onPressed: () async {
                    AppLog.d('Sync to Cloud task started');
                    SyncController.pushData();
                    Get.snackbar(
                        'Sync to Cloud', 'Data has been synced to cloud');
                  },
                )
              ],
            ),
            //send notification
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Enviar notificacion', style: titleStyle),
                IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () async {
                      AppLog.d('Send notification task started');
                      var firebasetoken = await UserController.getFirebaseToken(
                          'ayiimorenovega@gmail.com');
                      if (firebasetoken != null) {
                        AppLog.d('Firebase token: $firebasetoken');
                        await FirebaseApi.sendNotification(
                            to: firebasetoken,
                            title: "TaskerMG",
                            body: "Prueba de notificaciones desde app",
                            data: {"key": "value"});
                      } else {
                        AppLog.d('Firebase token not found');
                      }
                    })
              ],
            ),
          ],
        ),
      ),
    )
    );
  }
}
