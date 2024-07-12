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
        firebaseToken: json['firebaseToken'],
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
    };
  }
  
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE user (
        locId INTEGER PRIMARY KEY AUTOINCREMENT,
        userID INT UNIQUE,
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
