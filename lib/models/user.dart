import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import '../utils/AppLog.dart';

class User {
  int? locId;
  int? userID;
  String username;
  String? name;
  String email;
  String password;
  DateTime? creationDate;
  DateTime? lastUpdate;
  String? firebaseToken;
  Map<String, dynamic>? profileData;

  User({
    this.locId,
    this.userID,
    required this.username,
    this.name,
    required this.email,
    required this.password,
    this.creationDate,
    this.lastUpdate,
    this.firebaseToken,
    this.profileData,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        locId: json['locId'],
        userID: json['userID'],
        username: json['username'],
        name: json['name'],
        email: json['email'],
        password: json['password'],
        creationDate: DateTime.parse(json['creationDate']),
        lastUpdate: DateTime.parse(json['lastUpdate']),
        firebaseToken: json['firebaseToken'].toString(),
        profileData: json.containsKey('profileData') ? jsonDecode(json['profileData']) : null,
      );

  factory User.fromJsonWithProfile(Map<String, dynamic> json) => User(
        locId: json['locId'],
        userID: json['userID'],
        username: json['username'],
        name: json['name'],
        email: json['email'],
        password: json['password'],
        creationDate: json['creationDate'],
        lastUpdate: json['lastUpdate'],
        firebaseToken: json['firebaseToken'].toString(),
        profileData: json.containsKey('profileData') ? json['profileData'] : null,
      );

  Map<String, dynamic> toJson() => {
        'locId': locId,
        'userID': userID,
        'username': username,
        'name': name,
        'email': email,
        'password': password,
        'creationDate': creationDate?.toIso8601String(),
        'lastUpdate': lastUpdate?.toIso8601String(),
        'firebaseToken': firebaseToken,
        'profileData': profileData != null ? jsonEncode(profileData) : null,
      };

  Map<String, dynamic> toMap() {
    return {
      'locId': locId,
      'userID': userID,
      'username': username,
      'name': name,
      'email': email,
      'password': password,
      'creationDate': creationDate?.toIso8601String(),
      'lastUpdate': lastUpdate?.toIso8601String(),
      'firebaseToken': firebaseToken,
      'profileData': profileData != null ? jsonEncode(profileData) : null,
    };
  }

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE user (
        locId INTEGER PRIMARY KEY AUTOINCREMENT,
        userID INTEGER UNIQUE,
        username VARCHAR(100) NOT NULL UNIQUE,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        creationDate TEXT,
        salt VARCHAR(255) NOT NULL,
        lastUpdate TEXT,
        firebaseToken TEXT
      );
    ''');
    AppLog.d("Table User created");
  }
}

class ProfileData {
  int? locId;
  int? profileDataID;
  int? userID;
  String? profilePicUrl;
  DateTime? lastUpdate;

  ProfileData({
    this.locId,
    this.profileDataID,
    this.userID,
    this.profilePicUrl,
    this.lastUpdate,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
        locId: json['locId'],
        profileDataID: json['profileDataID'],
        userID: json['userID'],
        profilePicUrl: json['profilePicUrl'],
        lastUpdate: DateTime.parse(json['lastUpdate']),
      );

  Map<String, dynamic> toJson() => {
        'locId': locId,
        'profileDataID': profileDataID,
        'userID': userID,
        'profilePicUrl': profilePicUrl,
        'lastUpdate': lastUpdate?.toIso8601String(),
      };

  Map<String, dynamic> toMap() {
    return {
      'locId': locId,
      'profileDataID': profileDataID,
      'userID': userID,
      'profilePicUrl': profilePicUrl,
      'lastUpdate': lastUpdate?.toIso8601String(),
    };
  }

  //to mapstatic
  static Map<String, dynamic> toMapStatic(ProfileData profileData) {
    return {
      'locId': profileData.locId,
      'profileDataID': profileData.profileDataID,
      'userID': profileData.userID,
      'profilePicUrl': profileData.profilePicUrl,
      'lastUpdate': profileData.lastUpdate?.toIso8601String(),
    };
  }

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE profileData (
        locId INTEGER PRIMARY KEY AUTOINCREMENT,
        profileDataID INTEGER UNIQUE,
        userID INTEGER,
        profilePicUrl VARCHAR(255),
        lastUpdate TEXT,
        FOREIGN KEY (userID) REFERENCES user(userID) ON DELETE CASCADE
      );
    ''');
    AppLog.d("Table ProfileData created");
  }
}
