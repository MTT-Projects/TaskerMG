import 'package:crypt/crypt.dart';
import 'package:dos/db/db_helper.dart'; // Asegúrate de importar DBHelper correctamente
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:mysql1/mysql1.dart' as mysql;

import '../models/user.dart';

class UserController extends GetxController {
  static final UserController _instance = UserController._internal();

  factory UserController() {
    return _instance;
  }

  UserController._internal();

  User? _user;

  User? get user => _user;

  void setUser(User user) {
    _user = user;
  }

  static Future<bool> login(String username, String password) async {
    try {
      // Recupera el hash y la sal almacenados en la base de datos para el usuario dado
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
