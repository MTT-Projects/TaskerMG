import 'package:sqflite/sqflite.dart';
import '../models/task.dart';
import '../utils/AppLog.dart';

class LocalDB {
  static Database? _db;
  static final int _version = 1;
  static final String _tableName = "tasks";

  static Future<Database?> initDb() async {
    if (_db != null) {
      return _db;
    }
    try {
      String _path = '${await getDatabasesPath()}taskerMG_db.db'; // '${await getDatabasesPath()}tasks.db';
      _db = await openDatabase(_path, version: _version, onCreate: (db, version) async {
        AppLog.d("Creating a new one");
        await Task.createTable(db);  // Asegúrate de esperar a que la tabla se cree
        AppLog.d("Database initialized");
      });
    } catch (e) {
      AppLog.e(e.toString());
    }
    return _db;
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
    return await _db?.insert(_tableName, task!.toMap()) ?? 1;
  }

  static Future<List<Map<String, dynamic>>> query() async {
    print("query function called");
    return await _db!.query(_tableName);
  }

  static Future<int> delete(Task task) async {
    return await _db!.delete(_tableName, where: 'id = ?', whereArgs: [task.id]);
  }

  static Future<int> update(int id) async {
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