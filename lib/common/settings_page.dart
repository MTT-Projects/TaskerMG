import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taskermg/common/profileEditPage.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/common/widgets/splash.dart';
import 'package:taskermg/controllers/maincontroller.dart';
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
  bool _giveVerse = ThemeServices().isDark;
  String username = 'Usuario';
  String profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    var userID = MainController.getVar('currentUser');
    var user = await UserController.getUserData(userID);

    if (user != null) {
      setState(() {
        username = user["username"] ?? 'Usuario';
      });
      var profileData = await UserController.getProfileData(userID);
      if (profileData != null && profileData['profilePicUrl'] != null) {
        setState(() {
          profileImageUrl = profileData['profilePicUrl'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Saludo y perfil
              Text(
                'Hola, $username',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(height: 20),
              CircleAvatar(
                radius: 60,
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : AssetImage('Assets/images/profile.png') as ImageProvider,
                backgroundColor: Colors.grey,
              ),
              SizedBox(height: 40),
              // Editar perfil
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Editar perfil', style: titleStyle),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => const ProfileEditPage()));
                    },
                    child: Text(
                      "Editar",
                      style: TextStyle(color: AppColors.primaryColor),
                    ),
                  ),
                ],
              ),
              // Modo oscuro
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Modo oscuro', style: titleStyle),
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
                  ),
                ],
              ),
              // Cerrar sesión
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Cerrar sesión', style: titleStyle),
                  TextButton(
                    onPressed: () async {
                      AppLog.d('Logout task started');
                      await AuthService.logout();
                      //delete db
                      await LocalDB.dropDB();
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => const LoginScreen()));
                    },
                    child: Text(
                      "Cerrar",
                      style: TextStyle(color: AppColors.primaryColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
