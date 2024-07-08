// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:crypt/crypt.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/db/db_helper.dart'; // Asegúrate de importar DBHelper correctamente
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:mysql1/mysql1.dart' as mysql;
import 'package:taskermg/utils/AppLog.dart';

import '../models/user.dart';

class UserController extends GetxController {
  static final UserController _instance = UserController._internal();

  factory UserController() {
    return _instance;
  }

  UserController._internal();

  static User? _user;

  User? get user => _user;

  static MainController MC = MainController();

  static void setUser(User user) {
    _user = user;
  }

  static Future<bool> login(String username, String password) async {
    try {
      // Recupera el hash y la sal almacenataskermg en la base de datos para el usuario dado
      var result = await DBHelper.query(
          "SELECT password, salt FROM user WHERE username = ?", [username]);

      if (result.isNotEmpty) {
        var user = result.first;
        var storedHash = user['password'];
        var salt = user['salt'];

        // Genera el hash de la contraseña ingresada usando la misma sal
        var hashedPassword = Crypt.sha256(password, salt: salt).toString();

        // Compara el hash generado con el hash almacenado
        if (hashedPassword == storedHash) {
          setUserdataFromDB(username);
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Error en login: $e");
      // Puedes manejar diferentes tipos de errores aquí según sea necesario
      // Por ejemplo, podrías lanzar una excepción personalizada o retornar un código de error específico
      return false;
    }
  }

  static Future<void> setUserdataFromDB(username) async {
    //get user data from DB
    var result = await DBHelper.query(
        "SELECT * FROM user WHERE username = ?", [username]);

    if (result.isNotEmpty) {
      var user = result.first;
      AppLog.d("User data from DB: $user.");

      // Convertir el resultado a un mapa y luego a JSON
      final userData = {
        'userID': user['userID'],
        'username': user['username'],
        'name': user['name'],
        'email': user['email'],
        'password': user['password'],
        'creationDate': user['creationDate'].toString(),
        'salt': user['salt'],
        'lastUpdate': user['lastUpdate'].toString()
      };

      // Decodificar el JSON
      var userObj = User.fromJson(userData);
      setUser(userObj);

      MC.setVar('currentUser', userObj.userID);
      MC.setVar('userID', userObj.userID);
    }
  }

  static Future<dynamic> register(User user) async {
    var salt = Crypt.sha256(user.password).salt;
    var hashedPassword = Crypt.sha256(user.password, salt: salt).toString();
    var response = await DBHelper.query(
        "INSERT INTO user (username, name, email, password, salt) VALUES (?, ?, ?, ?, ?)",
        [user.username, user.name, user.email, hashedPassword, salt]);

    if (response is mysql.Results) {
      return true;
    } else {
      if (response['errorCode'] == '1062') {
        if (response['key'].toString().contains('username')) {
          return 'El nombre de usuario ya está en uso';
        } else if (response['key'].toString().contains('email')) {
          return 'El correo electrónico ya está en uso';
        }
      } else {
        return 'Error desconocido';
      }
    }
  }

  static Future<void> logout() async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
  }
}
