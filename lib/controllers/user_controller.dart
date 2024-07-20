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
import 'package:taskermg/db/db_local.dart';
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

  static void setUser(User user) {
    _user = user;
  }

  //get firebasetoken by email or username
  static Future<String?> getFirebaseToken(String email) async {
    final result = await DBHelper.query(
      'SELECT firebaseToken FROM user WHERE email = ?',
      [email],
    );
    if (result.isNotEmpty) {
      var token = result.first['firebaseToken'];
      var retstring = token.toString();
      return retstring;
    }
    return null;
  }

  //updateUserProfilePic(userId, downloadUrl)
  static Future<void> updateUserProfilePic(
      String userId, String downloadUrl) async {
    //check if profileData exists
    final result = await DBHelper.query(
      '''SELECT * FROM
        profileData 
      WHERE
        userID = ?
      ''',
      [userId],
    );
    if (result.isEmpty) {
      await DBHelper.query(
        '''INSERT INTO profileData 
        (userID, profilePicUrl, lastUpdate) 
        VALUES (?, ?, ?)
        ''',
        [userId, downloadUrl, DateTime.now().toIso8601String()],
      );
      return;
    } else {
      return await DBHelper.query(
        '''UPDATE profileData 
      SET 
        profilePicUrl = ?, 
        lastUpdate = ?
      WHERE 
        userID = ?
      ''',
        [downloadUrl, DateTime.now().toIso8601String(), userId],
      );
    }
  }

  //create user
  static Future<void> createUser(User user) async {
    await DBHelper.query(
      '''INSERT INTO user 
      (username, name, email, password, creationDate, lastUpdate, firebaseToken) 
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        user.username,
        user.name,
        user.email,
        user.password,
        user.creationDate?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        user.lastUpdate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        user.firebaseToken,
      ],
    );
  }

  //get profileData
  static Future<Map<String, dynamic>?> getProfileData(int userID) async {
    final result = await DBHelper.query(
      '''SELECT * FROM
        profileData 
      WHERE
        userID = ?
      ''',
      [userID],
    );
    if (result.isNotEmpty) {
      var profileData = result.first;
      Map<String, dynamic> profileDataMap = {
        'profileDataID': profileData['profileDataID'],
        'profilePicUrl': profileData['profilePicUrl'],
        'lastUpdate': profileData['lastUpdate']
      };
      return profileDataMap;
    }
    return null;
  }

  static Future<String> getProfilePicture(userID) async {

    var response  = await DBHelper.query(
      '''SELECT profilePicUrl FROM profileData WHERE userID = ?''',
      [userID],
    );


    if (response.isNotEmpty) {
      var profilePicUrl = response.first[0];
      return profilePicUrl;
    } else {
      return "";
    }
  }

  static getUserName(int? userID) {
    return DBHelper.query(
      '''SELECT name FROM user WHERE userID = ?''',
      [userID],
    );
  }
}
