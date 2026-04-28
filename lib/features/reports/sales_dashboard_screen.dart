import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/features/orders/transaction_provider.dart';
import 'package:hulu_coffee_pos/shared/widgets/app_header.dart';

class SalesDashboardScreen extends ConsumerWidget {
  const SalesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(todayStatsProvider);
    final topItemsAsync = ref.watch(topItemsProvider);
    final allTxAsync = ref.watch(allTransactionsProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: const AppHeader(title: 'Sales Report'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayStatsProvider);
          ref.invalidate(topItemsProvider);
          ref.invalidate(allTransactionsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ─────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('TODAY\'S OVERVIEW',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.onSurfaceVariant,
                                  letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Daily Report',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900)),
                        ]),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            const Icon(Icons.calendar_today, size: 14, color: AppTheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(DateFormat('d MMM yyyy').format(DateTime.now()),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Revenue card ────────────────────────────────────────
                    statsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox(),
                      data: (stats) {
                        final revenue = stats['revenue'] as double? ?? 0;
                        final orders = stats['orders'] as int? ?? 0;
                        final avg = stats['avg'] as double? ?? 0;
                        return Column(children: [
                          // Main revenue card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 6))],
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('GROSS REVENUE',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppTheme.onSurfaceVariant, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text(fmt.format(revenue),
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w900, color: AppTheme.primary)),
                              const SizedBox(height: 4),
                              Text('$orders orders today',
                                  style: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 13)),
                              const SizedBox(height: 20),
                              // Mini bar chart placeholder
                              _MiniBarChart(),
                            ]),
                          ),
                          const SizedBox(height: 16),
                          // Secondary stats
                          Row(children: [
                            Expanded(child: _MetricCard(
                              title: 'Total Orders', value: '$orders',
                              icon: Icons.receipt_long_rounded,
                              iconBg: AppTheme.secondaryContainer,
                              iconColor: AppTheme.onSecondaryContainer)),
                            const SizedBox(width: 16),
                            Expanded(child: _MetricCard(
                              title: 'Avg Ticket', value: orders > 0 ? fmt.format(avg) : 'Rp 0',
                              icon: Icons.payments_outlined,
                              iconBg: AppTheme.primaryFixedDim,
                              iconColor: AppTheme.primary)),
                          ]),
                        ]);
                      },
                    ),

                    const SizedBox(height: 32),

                    // ── Top Movers ──────────────────────────────────────────
                    Text('Top Selling Items',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    topItemsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox(),
                      data: (items) => items.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                              child: Column(children: [
                                Icon(Icons.bar_chart_rounded, size: 48, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
                                const SizedBox(height: 12),
                                Text('No sales data yet', style: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6))),
                              ]))
                          : Column(children: items.map((item) => _TopMoverItem(
                              name: item['name'] as String,
                              sold: '${item['qty']} sold',
                              revenue: fmt.format(item['revenue']))).toList()),
                    ),

                    const SizedBox(height: 32),

                    // ── Recent Transactions ─────────────────────────────────
                    Text('Recent Transactions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    allTxAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox(),
                      data: (txs) {
                        final recent = txs.take(5).toList();
                        if (recent.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                            child: Center(child: Text('No transactions yet',
                                style: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6)))));
                        }
                        return Column(children: recent.map((tx) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5))),
                          child: Row(children: [
                            Container(width: 40, height: 40,
                              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.receipt_rounded, color: AppTheme.primary, size: 20)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(tx.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('${tx.itemCount} items · ${DateFormat('HH:mm').format(tx.createdAt)}',
                                  style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7))),
                            ])),
                            Text(fmt.format(tx.total),
                                style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
                          ]),
                        )).toList());
                      },
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final heights = [0.3, 0.5, 0.6, 0.4, 0.8, 0.7, 0.5, 0.9, 1.0, 0.6, 0.4, 0.3];
    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: heights.asMap().entries.map((e) {
          final isPeak = e.key == 8;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 60 * e.value,
              decoration: BoxDecoration(
                color: isPeak ? AppTheme.primary : AppTheme.primaryFixedDim,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color iconBg, iconColor;
  const _MetricCard({required this.title, required this.value,
    required this.icon, required this.iconBg, required this.iconColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20)),
      const SizedBox(height: 12),
      Text(title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.onSurfaceVariant, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _TopMoverItem extends StatelessWidget {
  final String name, sold, revenue;
  const _TopMoverItem({required this.name, required this.sold, required this.revenue});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppTheme.surfaceContainerLow.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.local_cafe_rounded, color: AppTheme.onSurfaceVariant, size: 22)),
      const SizedBox(width: 14),
      Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(sold, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 14)),
        Text(revenue, style: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 11)),
      ]),
    ]),
  );
}
