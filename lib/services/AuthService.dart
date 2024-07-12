import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:crypt/crypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/user.dart';
import 'package:taskermg/utils/AppLog.dart';
import 'package:mysql1/mysql1.dart' as mysql;

class AuthService {
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  static const storage = FlutterSecureStorage();

  static Future<firebase_auth.User?> login(String username, String password) async {
    try {
      var result = await DBHelper.query(
          "SELECT password, salt, email FROM user WHERE username = ?", [username]);

      if (result.isNotEmpty) {
        var user = result.first;
        var storedHash = user['password'];
        var salt = user['salt'];
        var email = user['email'];

        var hashedPassword = Crypt.sha256(password, salt: salt).toString();

        if (hashedPassword == storedHash) {
          // Iniciar sesión en Firebase
          firebase_auth.UserCredential userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          firebase_auth.User? firebaseUser = userCredential.user;
          String? token = await firebaseUser?.getIdToken();

          if (firebaseUser != null) {
            await DBHelper.query(
              'UPDATE user SET firebaseToken = ? WHERE email = ?',
              [token, email],
            );
            await setUserdataFromDB(username);
            return firebaseUser;
          }
        }
      }
      return null;
    } catch (e) {
      AppLog.e("Error en login: $e");
      return null;
    }
  }

  static Future<void> setUserdataFromDB(String username) async {
    var result = await DBHelper.query(
        "SELECT * FROM user WHERE username = ?", [username]);

    if (result.isNotEmpty) {
      var user = result.first;
      AppLog.d("User data from DB: $user.");

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

      try {
        var userExists = await LocalDB.rawQuery(
            'SELECT * FROM user WHERE userID = ${user['userID']}');
        if (userExists.isEmpty) {
          await LocalDB.rawQuery(
              '''INSERT INTO user (userID, username, name, email, password, creationDate, salt, lastUpdate) 
          VALUES (
          ${user['userID']}, 
          '${user['username']}', 
          '${user['name']}', 
          '${user['email']}', 
          '${user['password']}', 
          '${user['creationDate']}', 
          '${user['salt']}', 
          '${user['lastUpdate']}')''');
        }
      } catch (e) {
        AppLog.e("Error al subir datos a LocalDB: $e");
      }

      var userObj = User.fromJson(userData);
      MainController.setVar('currentUser', userObj.userID ?? userObj.locId);
      MainController.setVar('userID', userObj.userID ?? userObj.locId);
    }
  }

  static Future<dynamic> register(User user) async {
    var salt = Crypt.sha256(user.password).salt;
    var hashedPassword = Crypt.sha256(user.password, salt: salt).toString();

    try {
      var response = await DBHelper.query(
          "INSERT INTO user (username, name, email, password, salt) VALUES (?, ?, ?, ?, ?)",
          [user.username, user.name, user.email, hashedPassword, salt]);

      if (response is mysql.Results) {
        // Registrar usuario en Firebase Auth
        firebase_auth.UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: user.email,
          password: user.password,
        );

        firebase_auth.User? firebaseUser = userCredential.user;
        String? token = await firebaseUser?.getIdToken();

        if (firebaseUser != null) {
          AppLog.d("token de usuario: ${token}");
          await DBHelper.query(
            'UPDATE user SET firebaseToken = ? WHERE email = ?',
            [token, user.email],
          );
        }

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
    } catch (e) {
      AppLog.e("Error en register: $e");
      return 'Error desconocido';
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
    await storage.deleteAll();
  }
}
