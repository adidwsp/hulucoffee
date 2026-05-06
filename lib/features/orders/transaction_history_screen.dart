import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/features/orders/transaction_provider.dart';
import 'package:hulu_coffee_pos/shared/models/transaction_model.dart';
import 'package:hulu_coffee_pos/shared/widgets/app_bottom_nav.dart';

final _filterProvider = StateProvider<String>((ref) => 'all');

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_filterProvider);

    final AsyncValue<List<Transaction>> txAsync = filter == 'all'
        ? ref.watch(allTransactionsProvider)
        : filter == 'today'
            ? ref.watch(todayTransactionsProvider)
            : ref.watch(weekTransactionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppTheme.primary,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primary, AppTheme.primaryContainer],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Transaction History',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('All completed orders',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13)),
                        ]),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: AppTheme.primary,
                child: Row(
                  children: ['all', 'today', 'week'].map((f) {
                    final label = f == 'all'
                        ? 'All'
                        : f == 'today'
                            ? 'Today'
                            : 'This Week';
                    final selected = filter == f;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            ref.read(_filterProvider.notifier).state = f,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: selected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(label,
                              style: TextStyle(
                                  color:
                                      selected ? Colors.white : Colors.white60,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 13)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
        body: txAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (txList) => txList.isEmpty
              ? _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: txList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _TxCard(tx: txList[i]),
                ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}

class _TxCard extends StatelessWidget {
  final Transaction tx;
  const _TxCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final timeFmt = DateFormat('HH:mm');
    final dateFmt = DateFormat('d MMM yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_rounded,
                color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(tx.orderNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                Text(fmt.format(tx.total),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppTheme.primary)),
              ]),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                    '${tx.itemCount} item${tx.itemCount == 1 ? '' : 's'} · ${tx.paymentMethod}',
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            AppTheme.onSurfaceVariant.withValues(alpha: 0.7))),
                Text(
                    '${dateFmt.format(tx.createdAt)} ${timeFmt.format(tx.createdAt)}',
                    style: TextStyle(
                        fontSize: 11,
                        color:
                            AppTheme.onSurfaceVariant.withValues(alpha: 0.5))),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
                color: AppTheme.surfaceContainerHigh, shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_rounded,
                size: 40,
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 16),
          const Text('No Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Complete an order from the POS to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 13)),
        ]),
      ),
    );
  }
}
