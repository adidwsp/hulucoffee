import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulu_coffee_pos/core/database/transaction_repository.dart';
import 'package:hulu_coffee_pos/shared/models/transaction_model.dart';

// ── All transactions ──────────────────────────────────────────────────────────
final allTransactionsProvider =
    AsyncNotifierProvider<TransactionNotifier, List<Transaction>>(
        TransactionNotifier.new);

class TransactionNotifier extends AsyncNotifier<List<Transaction>> {
  late TransactionRepository _repo;

  @override
  Future<List<Transaction>> build() async {
    _repo = ref.read(transactionRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }
}

// ── Filtered providers ────────────────────────────────────────────────────────
final transactionsByDateProvider = FutureProvider.family<List<Transaction>, DateTime>((ref, date) async {
  ref.watch(allTransactionsProvider);
  return ref.read(transactionRepositoryProvider).getByDate(date);
});

final transactionsByMonthProvider = FutureProvider.family<List<Transaction>, DateTime>((ref, month) async {
  ref.watch(allTransactionsProvider);
  return ref.read(transactionRepositoryProvider).getByMonth(month);
});

final todayTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  ref.watch(allTransactionsProvider);
  return ref.read(transactionRepositoryProvider).getToday();
});

final weekTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  ref.watch(allTransactionsProvider);
  return ref.read(transactionRepositoryProvider).getThisWeek();
});

// ── Today stats ───────────────────────────────────────────────────────────────
final todayStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(allTransactionsProvider);
  return ref.read(transactionRepositoryProvider).getTodayStats();
});

// ── Top items ─────────────────────────────────────────────────────────────────
final topItemsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(allTransactionsProvider);
  return ref.read(transactionRepositoryProvider).getTopItems(limit: 5);
});

// ── Period-based providers ────────────────────────────────────────────────────
final reportPeriodProvider = StateProvider<String>((ref) => 'today');

final statsByPeriodProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, period) async {
  ref.watch(allTransactionsProvider);
  return ref.read(transactionRepositoryProvider).getStatsByPeriod(period);
});

final topItemsByPeriodProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, period) async {
  ref.watch(allTransactionsProvider);
  return ref.read(transactionRepositoryProvider).getTopItemsByPeriod(period);
});

final paymentMethodStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, period) async {
  ref.watch(allTransactionsProvider);
  return ref.read(transactionRepositoryProvider).getPaymentMethodStats(period);
});

final peakHourStatsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, period) async {
  ref.watch(allTransactionsProvider);
  return ref.read(transactionRepositoryProvider).getPeakHourStats(period);
});

final weekComparisonProvider = FutureProvider<Map<String, double>>((ref) async {
  ref.watch(allTransactionsProvider);
  return ref.read(transactionRepositoryProvider).getWeekComparison();
});
