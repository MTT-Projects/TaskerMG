import 'package:mysql1/mysql1.dart';
import 'package:taskermg/controllers/conecctionChecker.dart';
import '../utils/AppLog.dart';

class DBHelper {
  static MySqlConnection? _connection;
  static ConnectionSettings? _settings;

  DBHelper._();


  static final DBHelper instance = DBHelper._();

  //verificar si hay internet
  

  static Future<void> initialize() async {
    //check internet connection
    if(await ConnectionChecker.checkConnection() == false)
    {
      AppLog.d("No internet connection, skipping DB initialization");
      return;
    }
    AppLog.d("Initializing DBHelper");
    
    _settings = ConnectionSettings(
      host: 'tasker-db-matiw172.d.aivencloud.com',
      port: 11312,
      user: 'avnadmin',
      password: 'AVNS_10qhYse1CcZic175-9l',
      db: 'taskermg_db',
    );
    await _connect();
  }

  static Future<void> _connect() async {
    if (_connection == null) {
      if (_settings == null) {
        throw Exception(
            'DBHelper is not initialized. Call initialize() first.');
      }
      try {
        _connection = await MySqlConnection.connect(_settings!);
      } catch (e) {
        AppLog.d("Error en _connect: $e");
        await Future.delayed(Duration(seconds: 5));
        _connection = await MySqlConnection.connect(_settings!);
      }
    }
  }

  static Future<MySqlConnection> get connection async {
    if (_connection == null) {
      throw Exception('DBHelper connection is not initialized.');
    }
    return _connection!;
  }

  static Future<void> closeConnection() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
  }

  static Future<dynamic> query(String sql, List<dynamic> values) async {
    AppLog.d("Query: $sql - $values");
    final conn = await connection;
    try {
      var result = await conn.query(sql, values);
      return result;
    } catch (e) {
      AppLog.d("Error en query: $e");
      return errorCatcher(e.toString());
    }
  }

  static dynamic errorCatcher(String errorString) {
    RegExp regExp = RegExp(r"Error (\d+) \((\d+)\): (.+)");
    Match? match = regExp.firstMatch(errorString);

    if (match != null) {
      String errorCode = match.group(1)!;
      String errorNumber = match.group(2)!;
      String errorMessage = match.group(3)!;

      String tableName = extractTableName(errorMessage);
      String duplicateEntry = extractDuplicateEntry(errorMessage);
      String key = extractKey(errorMessage);

      return {
        'errorCode': errorCode,
        'errorNumber': errorNumber,
        'errorMessage': errorMessage,
        'tableName': tableName,
        'duplicateEntry': duplicateEntry,
        'key': key,
      };
    } else {
      return {
        'errorCode': '-1',
        'errorNumber': '-1',
        'errorMessage': 'Error desconocido',
        'tableName': 'tabla desconocida',
        'duplicateEntry': 'N/A',
        'key': 'N/A',
      };
    }
  }

  static String extractTableName(String errorMessage) {
    RegExp tableNameRegExp = RegExp(r"table '(.+?)'");
    Match? tableNameMatch = tableNameRegExp.firstMatch(errorMessage);

    if (tableNameMatch != null) {
      return tableNameMatch.group(1)!;
    } else {
      return "tabla desconocida";
    }
  }

  static String extractDuplicateEntry(String errorMessage) {
    RegExp duplicateEntryRegExp = RegExp(r"Duplicate entry '(.+?)'");
    Match? duplicateEntryMatch = duplicateEntryRegExp.firstMatch(errorMessage);

    if (duplicateEntryMatch != null) {
      return duplicateEntryMatch.group(1)!;
    } else {
      return "N/A";
    }
  }

  static String extractKey(String errorMessage) {
    RegExp keyRegExp = RegExp(r"for key '(.+?)'");
    Match? keyMatch = keyRegExp.firstMatch(errorMessage);

    if (keyMatch != null) {
      return keyMatch.group(1)!;
    } else {
      return "N/A";
    }
  }
}
