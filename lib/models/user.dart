import 'package:sqflite/sqflite.dart';
import '../utils/AppLog.dart';

class User {
  int? userID;
  String username;
  String? name;
  String email;
  String password;
  DateTime? creationDate;
  DateTime? lastUpdate;

  User({
    this.userID,
    required this.username,
    this.name,
    required this.email,
    required this.password,
    this.creationDate,
    this.lastUpdate,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        userID: json['userID'],
        username: json['username'],
        name: json['name'],
        email: json['email'],
        password: json['password'],
        creationDate: DateTime.parse(json['creationDate']),
        lastUpdate: DateTime.parse(json['lastUpdate']),
      );

  Map<String, dynamic> toJson() => {
        'userID': userID,
        'username': username,
        'name': name,
        'email': email,
        'password': password,
        'creationDate': creationDate?.toIso8601String(),
        'lastUpdate': lastUpdate?.toIso8601String(),
      };

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE user (
        userID INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(100) NOT NULL UNIQUE,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        creationDate TEXT,
        salt VARCHAR(255) NOT NULL,
        lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      );
    ''');
    AppLog.d("Table User created");
  }
}
