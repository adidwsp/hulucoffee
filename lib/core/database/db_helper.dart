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
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        'hulu_coffee.db',
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final docsDir = await getApplicationDocumentsDirectory();
      final path = join(docsDir.path, 'hulu_coffee.db');
      return await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      final path = join(docsDir.path, 'hulu_coffee.db');
      return await openDatabase(
        path,
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createProductsTable(db);
    await _createTransactionsTable(db);
    await _createCategoriesTable(db);
    await _seedCategories(db);
    debugPrint('DEBUG: Database v$version created.');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('DEBUG: Upgrading DB from v$oldVersion to v$newVersion');
    if (oldVersion < 2) {
      await _createTransactionsTable(db);
    }
    if (oldVersion < 3) {
      await _createCategoriesTable(db);
      await _seedCategories(db);
    }
  }

  Future<void> _createProductsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        imageUrl TEXT,
        isAvailable INTEGER NOT NULL DEFAULT 1,
        category TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions(
        id TEXT PRIMARY KEY,
        orderNumber TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        itemsJson TEXT NOT NULL,
        total REAL NOT NULL,
        itemCount INTEGER NOT NULL,
        paymentMethod TEXT NOT NULL DEFAULT 'QRIS'
      )
    ''');
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        displayName TEXT NOT NULL,
        isBuiltIn INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _seedCategories(Database db) async {
    final seeds = [
      {
        'id': 'coffee',
        'name': 'coffee',
        'displayName': 'Coffee',
        'isBuiltIn': 1
      },
      {
        'id': 'nonCoffee',
        'name': 'nonCoffee',
        'displayName': 'Non-Coffee',
        'isBuiltIn': 1
      },
      {'id': 'tea', 'name': 'tea', 'displayName': 'Tea', 'isBuiltIn': 1},
      {
        'id': 'snacks',
        'name': 'snacks',
        'displayName': 'Snacks',
        'isBuiltIn': 1
      },
    ];
    for (final seed in seeds) {
      await db.insert('categories', seed,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
