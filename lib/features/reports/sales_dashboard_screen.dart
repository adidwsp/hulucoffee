import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/features/orders/transaction_provider.dart';
import 'package:hulu_coffee_pos/shared/widgets/app_header.dart';
import 'package:hulu_coffee_pos/shared/widgets/app_bottom_nav.dart';

class SalesDashboardScreen extends ConsumerWidget {
  const SalesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    final statsAsync = ref.watch(statsByPeriodProvider(period));
    final topItemsAsync = ref.watch(topItemsByPeriodProvider(period));
    final paymentAsync = ref.watch(paymentMethodStatsProvider(period));
    final peakAsync = ref.watch(peakHourStatsProvider(period));
    final weekAsync = ref.watch(weekComparisonProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: const AppHeader(title: 'Sales Report'),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statsByPeriodProvider);
          ref.invalidate(topItemsByPeriodProvider);
          ref.invalidate(paymentMethodStatsProvider);
          ref.invalidate(peakHourStatsProvider);
          ref.invalidate(weekComparisonProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
          children: [
            // ── Header + Period Selector ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('SALES REPORT',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(_periodLabel(period),
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                ]),
                _PeriodSelector(current: period, onChanged: (p) {
                  ref.read(reportPeriodProvider.notifier).state = p;
                }),
              ],
            ),
            const SizedBox(height: 24),

            // ── Revenue + Chart ───────────────────────────────────────────
            statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
              data: (stats) {
                final revenue = stats['revenue'] as double? ?? 0;
                final orders = stats['orders'] as int? ?? 0;
                final avg = stats['avg'] as double? ?? 0;
                final chartData = stats['chartData'] as List? ?? [];
                final productsSold = stats['productsSold'] as int? ?? 0;
                return Column(children: [
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
                      Text('$orders orders · $productsSold items sold',
                          style: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 13)),
                      const SizedBox(height: 20),
                      // Real chart
                      if (chartData.isNotEmpty)
                        _RevenueBarChart(chartData: chartData, period: period)
                      else
                        _EmptyChart(),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _MetricCard(
                        title: 'Total Orders', value: '$orders',
                        icon: Icons.receipt_long_rounded,
                        iconBg: AppTheme.secondaryContainer,
                        iconColor: AppTheme.onSecondaryContainer)),
                    const SizedBox(width: 16),
                    Expanded(child: _MetricCard(
                        title: 'Avg Ticket',
                        value: orders > 0 ? fmt.format(avg) : 'Rp 0',
                        icon: Icons.payments_outlined,
                        iconBg: AppTheme.primaryFixedDim,
                        iconColor: AppTheme.primary)),
                  ]),
                ]);
              },
            ),
            const SizedBox(height: 32),

            // ── Top Selling Items ─────────────────────────────────────────
            Text('Top Selling Items',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            topItemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
              data: (items) => items.isEmpty
                  ? _EmptyBox()
                  : Column(children: items.map((item) => _TopMoverItem(
                      name: item['name'] as String,
                      sold: '${item['qty']} sold',
                      revenue: fmt.format(item['revenue']))).toList()),
            ),
            const SizedBox(height: 32),

            // ── Payment Method Split ──────────────────────────────────────
            Text('Payment Split',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            paymentAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
              data: (p) => _PaymentSplitCard(data: p, fmt: fmt),
            ),
            const SizedBox(height: 32),

            // ── Peak Hours ────────────────────────────────────────────────
            Text('Peak Hours',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            peakAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
              data: (hours) => _PeakHoursCard(hours: hours),
            ),
            const SizedBox(height: 32),

            // ── Week vs Last Week ─────────────────────────────────────────
            Text('Weekly Comparison',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            weekAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
              data: (w) => _WeekComparisonCard(data: w, fmt: fmt),
            ),
          ],
        ),
      ),
    );
  }

  String _periodLabel(String p) {
    switch (p) {
      case 'week': return 'This Week';
      case 'month': return 'This Month';
      default: return 'Today';
    }
  }
}

// ── Period Selector ───────────────────────────────────────────────────────────
class _PeriodSelector extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _PeriodSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [('today', 'Today'), ('week', 'Week'), ('month', 'Month')];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((o) {
          final selected = current == o.$1;
          return GestureDetector(
            onTap: () => onChanged(o.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(o.$2,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppTheme.onSurfaceVariant)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Revenue Bar Chart ─────────────────────────────────────────────────────────
class _RevenueBarChart extends StatelessWidget {
  final List chartData;
  final String period;
  const _RevenueBarChart({required this.chartData, required this.period});

  @override
  Widget build(BuildContext context) {
    // Filter out zero bars for cleaner display; show max 12 bars
    final visible = chartData.where((d) => (d['value'] as num) > 0).toList();
    final display = visible.isEmpty ? chartData.take(8).toList() : visible;
    final maxVal = display.fold<double>(
        1, (m, d) => (d['value'] as num).toDouble() > m ? (d['value'] as num).toDouble() : m);

    return SizedBox(
      height: 120,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (g, gi, rod, ri) {
                return BarTooltipItem(
                  NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp ')
                      .format(rod.toY),
                  const TextStyle(color: Colors.white, fontSize: 10),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: display.length <= 8,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= display.length) return const SizedBox();
                  final label = display[idx]['label'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 8,
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6))),
                  );
                },
                reservedSize: 20,
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
                color: AppTheme.outlineVariant.withValues(alpha: 0.3), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(display.length, (i) {
            final val = (display[i]['value'] as num).toDouble();
            final isPeak = val == maxVal && maxVal > 0;
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: val,
                color: isPeak ? AppTheme.primary : AppTheme.primaryFixedDim,
                width: (200 / display.length).clamp(6, 24).toDouble(),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}

// ── Payment Split Card ────────────────────────────────────────────────────────
class _PaymentSplitCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final NumberFormat fmt;
  const _PaymentSplitCard({required this.data, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final qris = data['qris'] as int? ?? 0;
    final cash = data['cash'] as int? ?? 0;
    final qrisRev = data['qrisRev'] as double? ?? 0;
    final cashRev = data['cashRev'] as double? ?? 0;
    final total = qris + cash;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))]),
      child: total == 0
          ? Center(child: Text('No transactions yet', style: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5))))
          : Column(children: [
              Row(children: [
                Expanded(child: _SplitItem(
                    label: 'QRIS', count: qris, revenue: fmt.format(qrisRev),
                    color: AppTheme.primary, icon: Icons.qr_code_rounded,
                    pct: total > 0 ? qris / total : 0)),
                const SizedBox(width: 16),
                Expanded(child: _SplitItem(
                    label: 'Cash', count: cash, revenue: fmt.format(cashRev),
                    color: const Color(0xFF2E7D32), icon: Icons.payments_rounded,
                    pct: total > 0 ? cash / total : 0)),
              ]),
              const SizedBox(height: 16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: total > 0 ? qris / total : 0,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ]),
    );
  }
}

class _SplitItem extends StatelessWidget {
  final String label, revenue;
  final int count;
  final double pct;
  final Color color;
  final IconData icon;
  const _SplitItem({required this.label, required this.count, required this.revenue, required this.pct, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 6),
        Text('$count orders', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text('${(pct * 100).toStringAsFixed(0)}% · $revenue',
            style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7))),
      ]);
}

// ── Peak Hours Card ───────────────────────────────────────────────────────────
class _PeakHoursCard extends StatelessWidget {
  final List<Map<String, dynamic>> hours;
  const _PeakHoursCard({required this.hours});

  @override
  Widget build(BuildContext context) {
    // Group into 3-hour ranges
    final ranges = <String, int>{};
    for (final h in hours) {
      final hr = h['hour'] as int;
      final group = '${(hr ~/ 3) * 3}:00–${(hr ~/ 3) * 3 + 2}:59';
      ranges[group] = (ranges[group] ?? 0) + (h['count'] as int);
    }
    final maxCount = ranges.values.fold(0, (m, v) => v > m ? v : m);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))]),
      child: maxCount == 0
          ? Center(child: Text('No data yet', style: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5))))
          : Column(
              children: ranges.entries.map((e) {
                final frac = maxCount > 0 ? e.value / maxCount : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    SizedBox(width: 80, child: Text(e.key, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: frac,
                          minHeight: 18,
                          backgroundColor: AppTheme.surfaceContainerLow,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primary.withValues(alpha: 0.7 + frac * 0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ]),
                );
              }).toList(),
            ),
    );
  }
}

// ── Week Comparison Card ──────────────────────────────────────────────────────
class _WeekComparisonCard extends StatelessWidget {
  final Map<String, double> data;
  final NumberFormat fmt;
  const _WeekComparisonCard({required this.data, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final thisWeek = data['thisWeek'] ?? 0;
    final lastWeek = data['lastWeek'] ?? 0;
    final diff = thisWeek - lastWeek;
    final pct = lastWeek > 0 ? (diff / lastWeek * 100) : 0.0;
    final isUp = diff >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))]),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('THIS WEEK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.onSurfaceVariant, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(fmt.format(thisWeek), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: isUp ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(isUp ? Icons.trending_up : Icons.trending_down,
                size: 16, color: isUp ? const Color(0xFF2E7D32) : AppTheme.error),
            const SizedBox(width: 4),
            Text('${pct.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isUp ? const Color(0xFF2E7D32) : AppTheme.error)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('LAST WEEK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.onSurfaceVariant, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(fmt.format(lastWeek), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7))),
        ])),
      ]),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────
class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 80,
        decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text('No data for this period', style: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)))),
      );
}

class _EmptyBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Icon(Icons.bar_chart_rounded, size: 48, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text('No sales data', style: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6))),
        ]),
      );
}

class _MetricCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color iconBg, iconColor;
  const _MetricCard({required this.title, required this.value, required this.icon, required this.iconBg, required this.iconColor});

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
