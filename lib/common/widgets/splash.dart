// ignore_for_file: use_build_context_synchronously, no_leading_underscores_for_local_identifiers

import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/services.dart';
import 'package:taskermg/auth/login.dart';
import 'package:taskermg/common/intro_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taskermg/common/profileEditPage.dart';
import 'package:taskermg/common/validationScreen.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/profileDataController.dart';
import 'package:taskermg/services/AuthService.dart';

import '../../controllers/user_controller.dart';
import '../dashboard.dart';
import '../sync_screen.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  SplashState createState() => SplashState();
}

class SplashState extends State<Splash> with AfterLayoutMixin<Splash> {
  final storage = const FlutterSecureStorage();

  Future checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool _seen = (prefs.getBool('seen') ?? false);

    if (_seen) {
      checkIsLogin();
    } else {
      await prefs.setBool('seen', true);
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnBoardingPage()));
    }
  }

  Future<void> checkIsLogin() async {
    bool isLoggedIn = false;
    bool firstSync = true;
    String? savedUsername;
    String? savedPassword;

    try {
      isLoggedIn =
          await storage.read(key: 'isLoggedIn') == 'true' ? true : false;
      firstSync =
          await storage.read(key: 'firstSync') == 'false' ? true : false;
      savedUsername = await storage.read(key: 'username');

      savedPassword = await storage.read(key: 'password');
    } catch (e) {
      await storage.deleteAll();
    }

    if (isLoggedIn && savedUsername != null && savedPassword != null) {
      // Intenta iniciar sesión automáticamente
      var response = await AuthService.login(savedUsername, savedPassword);

      if (response != null) {
        if (response['validated'] != 1) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ValidationScreen(userId: response['userID'],  email: response['email']),
            ),
          );
          return;
        }

        var profileData = await ProfileDataController.getProfileDataByUserID(
            MainController.getVar('currentUser'));
        if (profileData != null) {
          if (firstSync) {
            MainController.setVar('onlyMine', true);
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => Dashboard()));
          } else {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => SyncScreen()));
            await storage.write(key: 'firstSync', value: 'false');
          }
        } else {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ProfileEditPage()));
        }

        return;
      }
    }

    // Si no hay sesión iniciada o las credenciales no son válidas, redirige a la pantalla de inicio de sesión
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  void afterFirstLayout(BuildContext context) => checkFirstSeen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('Assets/images/mylogo.png', width: 250),
      ),
    );
  }
}
