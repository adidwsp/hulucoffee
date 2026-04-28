import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulu_coffee_pos/core/database/db_helper.dart';
import 'package:hulu_coffee_pos/shared/models/category_model.dart';
import 'package:uuid/uuid.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

class CategoryRepository {
  final DBHelper _db = DBHelper();

  Future<List<Category>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('categories', orderBy: 'isBuiltIn DESC, displayName ASC');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<void> insert(Category category) async {
    final db = await _db.database;
    await db.insert('categories', category.toMap());
  }

  Future<void> update(Category category) async {
    final db = await _db.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Category buildNew(String displayName) {
    final name = displayName.trim().replaceAll(' ', '_').toLowerCase();
    return Category(
      id: const Uuid().v4(),
      name: name,
      displayName: displayName.trim(),
      isBuiltIn: false,
    );
  }
}
