import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulu_coffee_pos/core/database/db_helper.dart';
import 'package:hulu_coffee_pos/features/pos/providers/cart_provider.dart';
import 'package:hulu_coffee_pos/shared/models/transaction_model.dart';
import 'package:uuid/uuid.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

class TransactionRepository {
  final DBHelper _db = DBHelper();

  Future<List<Transaction>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('transactions', orderBy: 'createdAt DESC');
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<List<Transaction>> getToday() async {
    final db = await _db.database;
    final today = DateTime.now();
    final start =
        DateTime(today.year, today.month, today.day).toIso8601String();
    final end =
        DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
    final maps = await db.query(
      'transactions',
      where: 'createdAt BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<List<Transaction>> getThisWeek() async {
    final db = await _db.database;
    final now = DateTime.now();
    final weekStart =
        now.subtract(Duration(days: now.weekday - 1));
    final start =
        DateTime(weekStart.year, weekStart.month, weekStart.day).toIso8601String();
    final maps = await db.query(
      'transactions',
      where: 'createdAt >= ?',
      whereArgs: [start],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  /// Summary stats for today
  Future<Map<String, dynamic>> getTodayStats() async {
    final today = await getToday();
    final revenue = today.fold<double>(0, (sum, t) => sum + t.total);
    final orders = today.length;
    final avg = orders > 0 ? revenue / orders : 0.0;
    return {'revenue': revenue, 'orders': orders, 'avg': avg};
  }

  /// Top selling items from all transactions (returns [{name, qty, revenue}])
  Future<List<Map<String, dynamic>>> getTopItems({int limit = 5}) async {
    final all = await getAll();
    final Map<String, Map<String, dynamic>> totals = {};
    for (final tx in all) {
      for (final item in tx.items) {
        final name = item['name'] as String;
        final qty = (item['qty'] as num).toInt();
        final rev = (item['total'] as num).toDouble();
        if (totals.containsKey(name)) {
          totals[name]!['qty'] = (totals[name]!['qty'] as int) + qty;
          totals[name]!['revenue'] =
              (totals[name]!['revenue'] as double) + rev;
        } else {
          totals[name] = {'name': name, 'qty': qty, 'revenue': rev};
        }
      }
    }
    final sorted = totals.values.toList()
      ..sort((a, b) =>
          (b['qty'] as int).compareTo(a['qty'] as int));
    return sorted.take(limit).toList();
  }

  Future<Transaction> saveFromCart(CartState cart) async {
    final db = await _db.database;
    // Generate order number: count existing + 1
    final rows = await db.rawQuery('SELECT COUNT(*) as c FROM transactions');
    final count = rows.first['c'] as int? ?? 0;
    final orderNumber = '#${(count + 1).toString().padLeft(3, '0')}';

    final itemsJson = jsonEncode(cart.items.map((item) => {
          'name': item.product.name,
          'qty': item.quantity,
          'price': item.product.price,
          'total': item.totalPrice,
          'options': item.options.size ?? '',
        }).toList());

    final tx = Transaction(
      id: const Uuid().v4(),
      orderNumber: orderNumber,
      createdAt: DateTime.now(),
      itemsJson: itemsJson,
      total: cart.subtotal,
      itemCount: cart.itemCount,
      paymentMethod: 'QRIS',
    );

    await db.insert('transactions', tx.toMap());
    return tx;
  }
}
