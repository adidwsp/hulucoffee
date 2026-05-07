import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulu_coffee_pos/core/database/transaction_repository.dart';

/// Sort mode for POS product grid
enum SortMode { nameAsc, mostBought, latestBought }

final sortModeProvider = StateProvider<SortMode>((ref) => SortMode.nameAsc);

/// Product buy stats aggregated from transaction history
/// Returns Map<productName, {totalQty: int, lastBoughtAt: DateTime?}>
final productBuyStatsProvider =
    FutureProvider<Map<String, Map<String, dynamic>>>((ref) async {
  final repo = ref.read(transactionRepositoryProvider);
  return repo.getProductBuyStats();
});
