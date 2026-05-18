import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

  Future<List<Transaction>> getByDate(DateTime date) async {
    final db = await _db.database;
    final start = DateTime(date.year, date.month, date.day).toIso8601String();
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final maps = await db.query(
      'transactions',
      where: 'createdAt BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<List<Transaction>> getByMonth(DateTime month) async {
    final db = await _db.database;
    final start = DateTime(month.year, month.month, 1).toIso8601String();
    // To get the last day of the month, we can use the first day of the next month and subtract 1 millisecond.
    final end = DateTime(month.year, month.month + 1, 1).subtract(const Duration(milliseconds: 1)).toIso8601String();
    
    final maps = await db.query(
      'transactions',
      where: 'createdAt BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<List<Transaction>> getToday() async {
    return getByDate(DateTime.now());
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> update(Transaction tx) async {
    final db = await _db.database;
    await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<List<Transaction>> getThisWeek() async {
    final db = await _db.database;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
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

  Future<List<Transaction>> getLastWeek() async {
    final db = await _db.database;
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final start = DateTime(lastWeekStart.year, lastWeekStart.month, lastWeekStart.day).toIso8601String();
    final end = DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day)
        .subtract(const Duration(milliseconds: 1)).toIso8601String();
    final maps = await db.query(
      'transactions',
      where: 'createdAt BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<List<Transaction>> _getForPeriod(String period) async {
    switch (period) {
      case 'week': return getThisWeek();
      case 'month': return getByMonth(DateTime.now());
      default: return getToday();
    }
  }

  /// Stats (revenue, orders, avg, chartData) for a given period
  Future<Map<String, dynamic>> getStatsByPeriod(String period) async {
    final txs = await _getForPeriod(period);
    final revenue = txs.fold<double>(0, (s, t) => s + t.total);
    final orders = txs.length;
    final avg = orders > 0 ? revenue / orders : 0.0;

    // Build daily chart data
    final Map<String, double> dailyMap = {};
    for (final tx in txs) {
      final key = DateFormat('dd/MM').format(tx.createdAt);
      dailyMap[key] = (dailyMap[key] ?? 0) + tx.total;
    }
    // For "today" build hourly
    if (period == 'today') {
      final Map<String, double> hourly = {};
      for (final tx in txs) {
        final h = '${tx.createdAt.hour.toString().padLeft(2, '0')}:00';
        hourly[h] = (hourly[h] ?? 0) + tx.total;
      }
      final chartData = List.generate(24, (i) {
        final key = '${i.toString().padLeft(2, '0')}:00';
        return {'label': key, 'value': hourly[key] ?? 0.0};
      });
      return {
        'revenue': revenue, 'orders': orders, 'avg': avg,
        'chartData': chartData,
        'productsSold': txs.fold<int>(0, (s, t) => s + t.itemCount),
      };
    } else {
      // Sort by date
      final sortedKeys = dailyMap.keys.toList()..sort();
      final chartData = sortedKeys
          .map((k) => {'label': k, 'value': dailyMap[k]!})
          .toList();
      return {
        'revenue': revenue, 'orders': orders, 'avg': avg,
        'chartData': chartData,
        'productsSold': txs.fold<int>(0, (s, t) => s + t.itemCount),
      };
    }
  }

  /// Top items filtered by period
  Future<List<Map<String, dynamic>>> getTopItemsByPeriod(
      String period, {int limit = 5}) async {
    final txs = await _getForPeriod(period);
    final Map<String, Map<String, dynamic>> totals = {};
    for (final tx in txs) {
      for (final item in tx.items) {
        final name = item['name'] as String;
        final qty = (item['qty'] as num).toInt();
        final rev = (item['total'] as num).toDouble();
        if (totals.containsKey(name)) {
          totals[name]!['qty'] = (totals[name]!['qty'] as int) + qty;
          totals[name]!['revenue'] = (totals[name]!['revenue'] as double) + rev;
        } else {
          totals[name] = {'name': name, 'qty': qty, 'revenue': rev};
        }
      }
    }
    return (totals.values.toList()
          ..sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int)))
        .take(limit)
        .toList();
  }

  /// Payment method split for a period
  Future<Map<String, dynamic>> getPaymentMethodStats(String period) async {
    final txs = await _getForPeriod(period);
    int qris = 0, cash = 0;
    double qrisRev = 0, cashRev = 0;
    for (final tx in txs) {
      if (tx.paymentMethod.toUpperCase() == 'QRIS') {
        qris++; qrisRev += tx.total;
      } else {
        cash++; cashRev += tx.total;
      }
    }
    return {'qris': qris, 'cash': cash, 'qrisRev': qrisRev, 'cashRev': cashRev};
  }

  /// Peak hour distribution (returns map hour -> count)
  Future<List<Map<String, dynamic>>> getPeakHourStats(String period) async {
    final txs = await _getForPeriod(period);
    final Map<int, int> hourMap = {};
    for (final tx in txs) {
      final h = tx.createdAt.hour;
      hourMap[h] = (hourMap[h] ?? 0) + 1;
    }
    return List.generate(24, (i) => {'hour': i, 'count': hourMap[i] ?? 0});
  }

  /// Revenue comparison: this week vs last week
  Future<Map<String, double>> getWeekComparison() async {
    final thisWeek = await getThisWeek();
    final lastWeek = await getLastWeek();
    return {
      'thisWeek': thisWeek.fold(0.0, (s, t) => s + t.total),
      'lastWeek': lastWeek.fold(0.0, (s, t) => s + t.total),
    };
  }

  /// Summary stats for today
  Future<Map<String, dynamic>> getTodayStats() async {
    final today = await getToday();
    final revenue = today.fold<double>(0, (sum, t) => sum + t.total);
    final orders = today.length;
    final productsSold = today.fold<int>(0, (sum, t) {
      return sum + t.itemCount;
    });
    final avg = orders > 0 ? revenue / orders : 0.0;
    return {
      'revenue': revenue,
      'orders': orders,
      'productsSold': productsSold,
      'avg': avg
    };
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

  /// Returns buy stats per product name: {totalQty, lastBoughtAt}
  Future<Map<String, Map<String, dynamic>>> getProductBuyStats() async {
    final all = await getAll();
    final Map<String, Map<String, dynamic>> stats = {};
    for (final tx in all) {
      for (final item in tx.items) {
        final name = item['name'] as String;
        final qty = (item['qty'] as num).toInt();
        if (stats.containsKey(name)) {
          stats[name]!['totalQty'] = (stats[name]!['totalQty'] as int) + qty;
          final existing = stats[name]!['lastBoughtAt'] as DateTime;
          if (tx.createdAt.isAfter(existing)) {
            stats[name]!['lastBoughtAt'] = tx.createdAt;
          }
        } else {
          stats[name] = {
            'totalQty': qty,
            'lastBoughtAt': tx.createdAt,
          };
        }
      }
    }
    return stats;
  }

  Future<Transaction> saveFromCart(CartState cart,
      {String paymentMethod = 'QRIS'}) async {
    final db = await _db.database;
    // Generate order number: count existing + 1
    final rows = await db.rawQuery('SELECT COUNT(*) as c FROM transactions');
    final count = rows.first['c'] as int? ?? 0;
    final orderNumber = '#${(count + 1).toString().padLeft(3, '0')}';

    final itemsJson = jsonEncode(cart.items.map((item) {
      final optsSummary = [
        if (item.options.size != null) item.options.size,
        if (item.options.temperature != null) item.options.temperature,
        if (item.options.sugarLevel != null) item.options.sugarLevel,
        ...item.options.selectedAddons,
      ].whereType<String>().join(', ');

      return {
        'name': item.product.name,
        'qty': item.quantity,
        'price': item.product.price,
        'total': item.totalPrice,
        'options': optsSummary,
      };
    }).toList());

    final tx = Transaction(
      id: const Uuid().v4(),
      orderNumber: orderNumber,
      createdAt: DateTime.now(),
      itemsJson: itemsJson,
      total: cart.subtotal,
      itemCount: cart.itemCount,
      paymentMethod: paymentMethod,
    );

    await db.insert('transactions', tx.toMap());
    return tx;
  }
}
