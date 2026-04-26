import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    if (kIsWeb) {
      // Use web factory for sqflite
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        'hulu_coffee.db',
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // Use ffi factory for desktop
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final docsDir = await getApplicationDocumentsDirectory();
      final path = join(docsDir.path, 'hulu_coffee.db');
      return await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
        ),
      );
    } else {
      // Mobile platforms (Android/iOS)
      final docsDir = await getApplicationDocumentsDirectory();
      final path = join(docsDir.path, 'hulu_coffee.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        price REAL,
        imageUrl TEXT,
        isAvailable INTEGER,
        category TEXT
      )
    ''');
    print('DEBUG: Database tables created.');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
