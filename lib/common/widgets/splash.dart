// ignore_for_file: use_build_context_synchronously, no_leading_underscores_for_local_identifiers

import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/admob/v1.dart';
import 'package:lottie/lottie.dart';
import 'package:taskermg/auth/login.dart';
import 'package:taskermg/common/intro_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taskermg/common/profileEditPage.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/common/validationScreen.dart';
import 'package:taskermg/controllers/conecctionChecker.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/profileDataController.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/services/AuthService.dart';
import 'package:taskermg/utils/AppLog.dart';

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
    String? savedUserID;
    String? savedValidated;

    try {
      isLoggedIn =
          await storage.read(key: 'isLoggedIn') == 'true' ? true : false;
      firstSync =
          await storage.read(key: 'firstSync') == 'false' ? true : false;
      savedUsername = await storage.read(key: 'username');
      savedPassword = await storage.read(key: 'password');
      savedUserID = await storage.read(key: 'userID');
      savedValidated = await storage.read(key: 'validated');
      AppLog.d('isLoggedIn: $isLoggedIn');
      AppLog.d('firstSync: $firstSync');
      AppLog.d('savedUsername: $savedUsername');
      AppLog.d('savedPassword: $savedPassword');
      AppLog.d('savedUserID: $savedUserID');
      AppLog.d('savedValidated: $savedValidated');
      
    } catch (e) {
      AppLog.e('Error al leer datos de inicio de sesión: $e');
      await storage.deleteAll();
    }

    if (isLoggedIn &&
        savedUsername != null &&
        savedPassword != null &&
        savedUserID != null &&
        savedValidated != null) {
      if (await ConnectionChecker.checkConnection() == true) {
        // Intenta iniciar sesión automáticamente
        var response = await AuthService.login(savedUsername, savedPassword);

        if (response != null) {
          if (response['validated'] != 1) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => ValidationScreen(
                      userId: response['userID'], email: response['email'])),
              (Route<dynamic> route) => false,
            );
            return;
          }

          var profileData = await ProfileDataController.getProfileDataByUserID(
              MainController.getVar('currentUser'));
          if (profileData != null) {
            if (firstSync) {
              MainController.setVar('onlyMine', true);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => Dashboard()),
                (Route<dynamic> route) => false,
              );
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SyncScreen()),
                (Route<dynamic> route) => false,
              );
              await storage.write(key: 'firstSync', value: 'false');
            }
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => ProfileEditPage()),
              (Route<dynamic> route) => false,
            );
          }

          return;
        }
      } else {
        MainController.setVar('userID', int.parse(savedUserID));
        MainController.setVar("currentUser", int.parse(savedUserID));
        MainController.setVar('onlyMine', true);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      if (await ConnectionChecker.checkConnection() == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        //mostrar mensaje de no internet y no sesion iniciada
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => NoInternetScr()),
          (Route<dynamic> route) => false,
        );
      }
    }
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

//ventana de no conexion a internet
class NoInternetScr extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Container(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('Assets/lotties/noConnection.json',
                width: 200, height: 200),
            Text(
              'No se encontro una sesión activa y no hay conexion a internet',
              style: TextStyle(
                  fontSize: 20,
                  color: AppColors.textColor,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            ElevatedButton(
              onPressed: () async {
                await DBHelper.initialize();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => Splash()),
                  (Route<dynamic> route) => false,
                );
              },
              child: Text('Reintentar'),
            ),
          ],
        ),
      )),
    );
  }
}
