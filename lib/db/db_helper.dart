import 'package:mysql1/mysql1.dart';

class DBHelper {
  static MySqlConnection? _connection;
  static ConnectionSettings? _settings;

  DBHelper._();

  static final DBHelper instance = DBHelper._();

  static Future<void> initialize() async {
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
        throw Exception('DBHelper is not initialized. Call initialize() first.');
      }
      _connection = await MySqlConnection.connect(_settings!);
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

  static Future<void> query(String sql, List<dynamic> values) async {
    final conn = await connection;
    await conn.query(sql, values);
  }
}
