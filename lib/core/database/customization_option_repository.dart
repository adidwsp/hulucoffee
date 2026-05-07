import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulu_coffee_pos/core/database/db_helper.dart';
import 'package:hulu_coffee_pos/shared/models/customization_option_model.dart';
import 'package:uuid/uuid.dart';

final customizationOptionRepositoryProvider =
    Provider<CustomizationOptionRepository>((ref) {
  return CustomizationOptionRepository();
});

class CustomizationOptionRepository {
  final DBHelper _db = DBHelper();

  Future<List<CustomizationOption>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('customization_options',
        orderBy: 'type ASC, sortOrder ASC');
    return maps.map((m) => CustomizationOption.fromMap(m)).toList();
  }

  Future<List<CustomizationOption>> getByType(String type) async {
    final db = await _db.database;
    final maps = await db.query('customization_options',
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'sortOrder ASC');
    return maps.map((m) => CustomizationOption.fromMap(m)).toList();
  }

  Future<List<CustomizationOption>> getActiveByType(String type) async {
    final db = await _db.database;
    final maps = await db.query('customization_options',
        where: 'type = ? AND isActive = 1',
        whereArgs: [type],
        orderBy: 'sortOrder ASC');
    return maps.map((m) => CustomizationOption.fromMap(m)).toList();
  }

  Future<void> insert(CustomizationOption option) async {
    final db = await _db.database;
    await db.insert('customization_options', option.toMap());
  }

  Future<void> update(CustomizationOption option) async {
    final db = await _db.database;
    await db.update(
      'customization_options',
      option.toMap(),
      where: 'id = ?',
      whereArgs: [option.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('customization_options', where: 'id = ?', whereArgs: [id]);
  }

  CustomizationOption buildNew({
    required String type,
    required String label,
    String subtitle = '',
    double priceModifier = 0,
    int sortOrder = 99,
  }) {
    return CustomizationOption(
      id: const Uuid().v4(),
      type: type,
      label: label,
      subtitle: subtitle,
      priceModifier: priceModifier,
      sortOrder: sortOrder,
      isActive: true,
    );
  }
}
