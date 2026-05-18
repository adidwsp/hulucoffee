import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/features/orders/transaction_provider.dart';
import 'package:hulu_coffee_pos/shared/widgets/app_bottom_nav.dart';

final _currFmt =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

// Dashboard-local period filter (independent from reports page)
final _dashPeriodProvider = StateProvider<String>((ref) => 'today');

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 👋';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_dashPeriodProvider);
    final statsAsync = ref.watch(statsByPeriodProvider(period));
    final topItemsAsync = ref.watch(topItemsByPeriodProvider(period));
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(now);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final leave = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Exit App?'),
              content: const Text('Do you want to exit Hulu Coffee POS?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary),
                  child: const Text('Exit', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          if (leave == true && context.mounted) {}
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(statsByPeriodProvider);
            ref.invalidate(topItemsByPeriodProvider);
            ref.invalidate(allTransactionsProvider);
          },
          child: CustomScrollView(
            slivers: [
              // ── Hero Header ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 280,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0D47A1), Color(0xFF002171)]),
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(50),
                            bottomRight: Radius.circular(50)),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_greeting(),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 6),
                                      const Text('Hulu Coffee',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 32,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.5)),
                                      const SizedBox(height: 8),
                                      Text(dateStr,
                                          style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.7),
                                              fontSize: 13)),
                                    ]),
                              ),
                              Container(
                                width: 56, height: 56,
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16)),
                                child: const Icon(Icons.storefront_rounded,
                                    color: Colors.white, size: 32),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Overlapping stats card
                    Padding(
                      padding: const EdgeInsets.only(top: 180, left: 20, right: 20),
                      child: statsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const SizedBox(),
                        data: (stats) => _buildSalesCard(context, ref, stats, period),
                      ),
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Quick Actions ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('Quick Actions'),
                        const SizedBox(height: 16),
                        Row(children: [
                          _QuickAction(
                              icon: Icons.point_of_sale_rounded,
                              label: 'Open POS',
                              color: const Color(0xFF1565C0),
                              onTap: () => context.goNamed('home')),
                          const SizedBox(width: 12),
                          _QuickAction(
                              icon: Icons.restaurant_menu_rounded,
                              label: 'Manage Menu',
                              color: const Color(0xFF2E7D32),
                              onTap: () => context.pushNamed('menu')),
                          const SizedBox(width: 12),
                          _QuickAction(
                              icon: Icons.insert_chart_rounded,
                              label: 'Sales Report',
                              color: const Color(0xFF6A1B9A),
                              onTap: () => context.pushNamed('reports')),
                        ]),
                      ]),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Top Items ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _SectionTitle('Top Selling Items'),
                              TextButton(
                                  onPressed: () => context.pushNamed('history'),
                                  child: const Text('View History',
                                      style: TextStyle(color: AppTheme.primary))),
                            ]),
                        const SizedBox(height: 8),
                        topItemsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const SizedBox(),
                          data: (items) => items.isEmpty
                              ? _emptyCard()
                              : Column(
                                  children: items.asMap().entries.map((e) {
                                  final i = e.value;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.outlineVariant)),
                                    child: Row(children: [
                                      Container(
                                          width: 8, height: 8,
                                          decoration: const BoxDecoration(
                                              color: AppTheme.primary, shape: BoxShape.circle)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Text(i['name'] as String,
                                              style: const TextStyle(fontWeight: FontWeight.w600))),
                                      Text('${i['qty']} sold',
                                          style: const TextStyle(
                                              color: AppTheme.primary, fontWeight: FontWeight.w700)),
                                      const SizedBox(width: 12),
                                      Text(_currFmt.format(i['revenue']),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7))),
                                    ]),
                                  );
                                }).toList()),
                        ),
                      ]),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      ),
    );
  }

  Widget _emptyCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineVariant)),
        child: Column(children: [
          Icon(Icons.bar_chart_rounded,
              size: 40, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text('No data yet',
              style: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5))),
        ]),
      );

  Widget _buildSalesCard(BuildContext context, WidgetRef ref,
      Map<String, dynamic> stats, String period) {
    final revenue = stats['revenue'] ?? 0;
    final orders = stats['orders'] ?? 0;
    final productsSold = stats['productsSold'] ?? 0;

    const options = [
      ('today', 'Today'),
      ('week', 'This Week'),
      ('month', 'This Month'),
    ];
    final label = options.firstWhere((o) => o.$1 == period, orElse: () => ('today', 'Today')).$2;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("Sales Overview",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
          // Active period dropdown
          GestureDetector(
            onTap: () => _showPeriodPicker(context, ref, period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: AppTheme.primary),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Text(
          _currFmt.format(revenue),
          style: const TextStyle(
              fontSize: 40, fontWeight: FontWeight.w900,
              color: AppTheme.onSurface, letterSpacing: -1.0),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1, color: AppTheme.outlineVariant),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(color: Color(0xFFEAF2FF), shape: BoxShape.circle),
              child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF1565C0), size: 22),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Total Orders",
                  style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
              Text("$orders",
                  style: const TextStyle(fontSize: 18, color: AppTheme.onSurface, fontWeight: FontWeight.w700)),
            ]),
          ])),
          Container(width: 1, height: 40, color: AppTheme.outlineVariant),
          Expanded(child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2E7D32), size: 22),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Products Sold",
                    style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                Text("$productsSold",
                    style: const TextStyle(fontSize: 18, color: AppTheme.onSurface, fontWeight: FontWeight.w700)),
              ]),
            ]),
          )),
        ]),
      ]),
    );
  }

  void _showPeriodPicker(BuildContext context, WidgetRef ref, String current) {
    const options = [
      ('today', 'Today', Icons.today_rounded),
      ('week', 'This Week', Icons.date_range_rounded),
      ('month', 'This Month', Icons.calendar_month_rounded),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.outlineVariant, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          const Text('Select Period',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...options.map((o) => ListTile(
                leading: Icon(o.$3, color: current == o.$1 ? AppTheme.primary : AppTheme.onSurfaceVariant),
                title: Text(o.$2, style: TextStyle(fontWeight: FontWeight.w600,
                    color: current == o.$1 ? AppTheme.primary : AppTheme.onSurface)),
                trailing: current == o.$1 ? const Icon(Icons.check_rounded, color: AppTheme.primary) : null,
                onTap: () {
                  ref.read(_dashPeriodProvider.notifier).state = o.$1;
                  Navigator.pop(ctx);
                },
              )),
        ]),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: AppTheme.onSurface, letterSpacing: -0.3));
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.1))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 16),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w700, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
      );
}
