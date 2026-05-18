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
          version: 6,
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
          version: 7,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      final path = join(docsDir.path, 'hulu_coffee.db');
      return await openDatabase(
        path,
        version: 7,
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
    await _createCustomizationOptionsTable(db);
    await _seedCustomizationOptions(db);
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
    if (oldVersion < 4) {
      await _createCustomizationOptionsTable(db);
      await _seedCustomizationOptions(db);
    }
    if (oldVersion < 5) {
      // Add enabledOptions column — default all options enabled
      await db.execute(
        "ALTER TABLE products ADD COLUMN enabledOptions TEXT NOT NULL DEFAULT '[\"size\",\"temperature\",\"sugar_level\",\"addon\"]'"
      );
    }
    if (oldVersion < 6) {
      // Add optionPriceOverrides column — default empty map
      await db.execute(
        "ALTER TABLE products ADD COLUMN optionPriceOverrides TEXT NOT NULL DEFAULT '{}'"
      );
    }
    if (oldVersion < 7) {
      // Add paymentMethod column to transactions if it doesn't exist
      try {
        await db.execute(
          "ALTER TABLE transactions ADD COLUMN paymentMethod TEXT NOT NULL DEFAULT 'QRIS'"
        );
      } catch (e) {
        debugPrint('DEBUG: Column paymentMethod might already exist: $e');
      }
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
        category TEXT NOT NULL,
        enabledOptions TEXT NOT NULL DEFAULT '["size","temperature","sugar_level","addon"]',
        optionPriceOverrides TEXT NOT NULL DEFAULT '{}'
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

  Future<void> _createCustomizationOptionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customization_options(
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        label TEXT NOT NULL,
        subtitle TEXT NOT NULL DEFAULT '',
        priceModifier REAL NOT NULL DEFAULT 0,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        isActive INTEGER NOT NULL DEFAULT 1
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

  Future<void> _seedCustomizationOptions(Database db) async {
    final seeds = [
      // Sizes — Small free, Medium +3000, Large +6000
      {'id': 'size_small', 'type': 'size', 'label': 'Small', 'subtitle': '12 oz', 'priceModifier': 0.0, 'sortOrder': 0, 'isActive': 1},
      {'id': 'size_medium', 'type': 'size', 'label': 'Medium', 'subtitle': '16 oz', 'priceModifier': 3000.0, 'sortOrder': 1, 'isActive': 1},
      {'id': 'size_large', 'type': 'size', 'label': 'Large', 'subtitle': '20 oz', 'priceModifier': 6000.0, 'sortOrder': 2, 'isActive': 1},
      // Temperatures — no price modifier
      {'id': 'temp_hot', 'type': 'temperature', 'label': 'Hot', 'subtitle': '', 'priceModifier': 0.0, 'sortOrder': 0, 'isActive': 1},
      {'id': 'temp_iced', 'type': 'temperature', 'label': 'Iced', 'subtitle': '', 'priceModifier': 0.0, 'sortOrder': 1, 'isActive': 1},
      // Sugar Levels — no price modifier
      {'id': 'sugar_none', 'type': 'sugar_level', 'label': 'No Sugar', 'subtitle': '', 'priceModifier': 0.0, 'sortOrder': 0, 'isActive': 1},
      {'id': 'sugar_25', 'type': 'sugar_level', 'label': '25%', 'subtitle': '', 'priceModifier': 0.0, 'sortOrder': 1, 'isActive': 1},
      {'id': 'sugar_50', 'type': 'sugar_level', 'label': '50%', 'subtitle': '', 'priceModifier': 0.0, 'sortOrder': 2, 'isActive': 1},
      {'id': 'sugar_normal', 'type': 'sugar_level', 'label': 'Normal', 'subtitle': '', 'priceModifier': 0.0, 'sortOrder': 3, 'isActive': 1},
      // Add-ons — price modifier applies
      {'id': 'addon_espresso', 'type': 'addon', 'label': 'Extra Espresso Shot', 'subtitle': '', 'priceModifier': 15000.0, 'sortOrder': 0, 'isActive': 1},
      {'id': 'addon_oatmilk', 'type': 'addon', 'label': 'Oat Milk', 'subtitle': '', 'priceModifier': 10000.0, 'sortOrder': 1, 'isActive': 1},
    ];
    for (final seed in seeds) {
      await db.insert('customization_options', seed,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
