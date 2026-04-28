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
final todayTransactionsProvider = FutureProvider<List<Transaction>>((ref) {
  return ref.read(transactionRepositoryProvider).getToday();
});

final weekTransactionsProvider = FutureProvider<List<Transaction>>((ref) {
  return ref.read(transactionRepositoryProvider).getThisWeek();
});

// ── Today stats ───────────────────────────────────────────────────────────────
final todayStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.read(transactionRepositoryProvider).getTodayStats();
});

// ── Top items ─────────────────────────────────────────────────────────────────
final topItemsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(transactionRepositoryProvider).getTopItems(limit: 5);
});
