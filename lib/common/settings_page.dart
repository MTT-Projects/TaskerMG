// ignore_for_file: use_build_context_synchronously, prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:taskermg/common/profileEditPage.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/common/widgets/splash.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/user_controller.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/services/AuthService.dart';
import 'package:taskermg/services/theme_services.dart';
import 'package:taskermg/utils/AppLog.dart';

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
      backgroundColor: AppColors.backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30.0),
            bottomRight: Radius.circular(30.0),
          ),
          child: AppBar(
            title: Text('Configuración', style: TextStyle(color: AppColors.secTextColor)),
            backgroundColor: AppColors.secBackgroundColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.secTextColor),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: [
            // Saludo y perfil
            Center(
              child: Column(
                children: [
                  Text(
                    'Hola, $username',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 100,
                    backgroundImage: profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : const AssetImage('Assets/images/profile.png')
                            as ImageProvider,
                    backgroundColor: Colors.grey,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Opciones
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: Icon(Icons.edit, color: AppColors.secondaryColor),
                    title: Text('Editar perfil', style: titleStyle),
                    trailing: Icon(Icons.arrow_forward_ios, color: AppColors.secondaryColor),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const ProfileEditPage()));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.dark_mode, color: AppColors.secondaryColor),
                    title: Text('Modo oscuro', style: titleStyle),
                    trailing: CupertinoSwitch(
                      value: _giveVerse,
                      onChanged: (bool value) {
                        _themeController.switchTheme();
                        setState(() {
                          _giveVerse = value;
                        });
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const Splash()),
                          (Route<dynamic> route) => false,
                        );
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: AppColors.secondaryColor),
                    title: Text('Cerrar sesión', style: titleStyle),
                    trailing: Icon(Icons.arrow_forward_ios, color: AppColors.secondaryColor),
                    onTap: () {
                      _showLogoutDialog();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cerrar sesión'),
          content: Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                AppLog.d('Logout task started');
                await AuthService.logout();
                await LocalDB.dropDB();
                await const FlutterSecureStorage().deleteAll();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Splash()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
