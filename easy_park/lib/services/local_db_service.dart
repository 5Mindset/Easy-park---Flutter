import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class LocalDbService {
  static Database? _db;

  static Future<Database> _getDatabase() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'easypark.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user_login (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT,
            token TEXT,
            role TEXT,
            user_json TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          final columns = await db.rawQuery("PRAGMA table_info(user_login)");
          final columnNames = columns.map((col) => col['name']).toList();
          if (!columnNames.contains('user_json')) {
            await db.execute('ALTER TABLE user_login ADD COLUMN user_json TEXT');
          }
        }
      },
    );
    return _db!;
  }

  static Future<void> init() async {
    await _getDatabase();
  }

  static Future<void> saveLogin({
    required String email,
    required String token,
    required String role,
    required String userJson,
  }) async {
    final db = await _getDatabase();
    await db.delete('user_login');
    await db.insert(
      'user_login',
      {
        'email': email,
        'token': token,
        'role': role,
        'user_json': userJson,
      },
    );
  }

  static Future<Map<String, dynamic>?> getLogin() async {
    final db = await _getDatabase();
    final result = await db.query('user_login', limit: 1);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    return await getLogin();
  }

  static Future<void> deleteLogin() async {
    final db = await _getDatabase();
    await db.delete('user_login');
  }

  static Future<void> closeDb() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}

