import 'package:sqflite/sqflite.dart';
import 'package:hulu_coffee_pos/core/database/db_helper.dart';
import 'package:hulu_coffee_pos/shared/models/product_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulu_coffee_pos/shared/dummy_data.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

class ProductRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<List<Product>> getProducts() async {
    final db = await _dbHelper.database;
    final maps = await db.query('products');
    
    if (maps.isEmpty) {
      // Seed database with dummy data if empty
      await seedDatabase();
      return dummyProducts;
    }

    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  Future<void> insertProduct(Product product) async {
    final db = await _dbHelper.database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> seedDatabase() async {
    for (var product in dummyProducts) {
      await insertProduct(product);
    }
  }
}
