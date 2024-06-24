import 'package:sqflite/sqflite.dart';

import '../models/task.dart';

class LocalDB {
  static Database? _db;
  static final int _version = 1;
  static final String _tableName = "tasks";

  static Future<void> initDb() async {
    if (_db != null) {
      return;
    }
    try {
      String _path = await getDatabasesPath() +
          'tasks.db'; // '${await getDatabasesPath()}tasks.db';
      _db =
          await openDatabase(_path, version: _version, onCreate: (db, version) {
        print("Creating a new one");
        return db.execute(
          "CREATE TABLE $_tableName ("
          "id INTEGER PRIMARY KEY AUTOINCREMENT, "
          "title STRING, note TEXT, date STRING, "
          "startTime STRING, endTime STRING, "
          //"remind INTEGER, "
          "repeat STRING, "
          "color INTEGER, "
          //"alarmTime STRING, "
          "isCompleted INTEGER)",
        );
      });
    } catch (e) {
      print(e);
    }
  }

  static Database get db {
    if (_db != null) {
      return _db!;
    } else {
      initDb();
      return _db!;
    }
  }

  static Future<int> insert(Task? task) async {
    print("Insert function called");
    return await _db?.insert(_tableName, task!.toJson()) ?? 1;
  }

  static Future<List<Map<String, dynamic>>> query() async {
    print("query function called");
    return await _db!.query(_tableName);
  }

  static delete(Task task) async {
    return await _db!.delete(_tableName, where: 'id =? ', whereArgs: [task.id]);
  }

  static update(int id) async {
    return await _db!.rawUpdate('''
        UPDATE tasks
        SET isCompleted = ?
        WHERE id = ?
    ''', [1, id]);
  }

/*
  static getCount() async {
    var x = await _db!.rawQuery('SELECT COUNT (*) from  $_tableName ');
    int count = Sqflite.firstIntValue(x)!.toInt();
    return count;
  }
  */
}