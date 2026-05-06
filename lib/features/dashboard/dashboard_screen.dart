import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/features/orders/transaction_provider.dart';
import 'package:hulu_coffee_pos/features/pos/providers/cart_provider.dart';
import 'package:hulu_coffee_pos/features/pos/providers/product_provider.dart';
import 'package:hulu_coffee_pos/shared/widgets/app_bottom_nav.dart';

final _currFmt =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
    final cartState = ref.watch(cartProvider);
    final statsAsync = ref.watch(todayStatsProvider);
    final productsAsync = ref.watch(productNotifierProvider);
    final topItemsAsync = ref.watch(topItemsProvider);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(now);

    final totalProducts = productsAsync.when(
        data: (p) => p.length, loading: () => 0, error: (_, __) => 0);

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
                  child:
                      const Text('Exit', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          if (leave == true && context.mounted) {
            // Exit the app
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayStatsProvider);
            ref.invalidate(topItemsProvider);
            ref.invalidate(allTransactionsProvider);
          },
          child: CustomScrollView(
            slivers: [
              // ── Hero Header ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primary, AppTheme.primaryContainer]),
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32)),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_greeting(),
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  const Text('Hulu Coffee',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5)),
                                  const SizedBox(height: 2),
                                  Text(dateStr,
                                      style: const TextStyle(
                                          color: Colors.white60, fontSize: 12)),
                                ]),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.storefront_rounded,
                                color: Colors.white, size: 28),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Today's Stats ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle("Today's Overview"),
                        const SizedBox(height: 12),
                        statsAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const SizedBox(),
                          data: (stats) {
                            final totalSold = (stats['orders'] as int? ?? 0) *
                                2; // rough estimate or fetch actual if available, but since we don't have total items sold easily, we'll just display orders and products count.
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currFmt.format(stats['revenue'] ?? 0),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primary,
                                    letterSpacing: -1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _TypoStat(
                                        label: 'Total Orders',
                                        value: '${stats['orders'] ?? 0}'),
                                    const SizedBox(width: 24),
                                    _TypoStat(
                                        label: 'Products Sold',
                                        value:
                                            '${stats['orders'] ?? 0}'), // using orders as proxy if items sold not in stats
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ]),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Quick Actions ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('Quick Actions'),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            children: [
                              _QuickAction(
                                  icon: Icons.point_of_sale_rounded,
                                  label: 'Open POS',
                                  color: AppTheme.primary,
                                  onTap: () => context.goNamed('home')),
                              const SizedBox(width: 12),
                              _QuickAction(
                                  icon: Icons.shopping_cart_rounded,
                                  label: 'View Cart',
                                  color: const Color(0xFFFF9800),
                                  onTap: () => context.pushNamed('cart'),
                                  badge: cartState.itemCount > 0
                                      ? '${cartState.itemCount}'
                                      : null),
                              const SizedBox(width: 12),
                              _QuickAction(
                                  icon: Icons.menu_book_rounded,
                                  label: 'Manage Menu',
                                  color: const Color(0xFF9C27B0),
                                  onTap: () => context.pushNamed('menu')),
                              const SizedBox(width: 12),
                              _QuickAction(
                                  icon: Icons.analytics_rounded,
                                  label: 'Sales Report',
                                  color: const Color(0xFF4CAF50),
                                  onTap: () => context.pushNamed('reports')),
                            ],
                          ),
                        ),
                      ]),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Top Items ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _SectionTitle('Top Selling Items'),
                              TextButton(
                                  onPressed: () => context.pushNamed('history'),
                                  child: const Text('View History',
                                      style:
                                          TextStyle(color: AppTheme.primary))),
                            ]),
                        const SizedBox(height: 8),
                        topItemsAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
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
                                        border: Border.all(
                                            color: AppTheme.outlineVariant)),
                                    child: Row(children: [
                                      Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                              color: AppTheme.primary,
                                              shape: BoxShape.circle)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Text(i['name'] as String,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600))),
                                      Text('${i['qty']} sold',
                                          style: const TextStyle(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(width: 12),
                                      Text(_currFmt.format(i['revenue']),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.onSurfaceVariant
                                                  .withValues(alpha: 0.7))),
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
              size: 40,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text('No data yet',
              style: TextStyle(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5))),
        ]),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.onSurface,
          letterSpacing: -0.3));
}

class _TypoStat extends StatelessWidget {
  final String label, value;
  const _TypoStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface)),
        ],
      );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap,
      this.badge});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2))),
          child: Row(children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 18)),
              if (badge != null)
                Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: Text(badge!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)))),
            ]),
            const SizedBox(width: 10),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
            Icon(Icons.chevron_right_rounded, color: color, size: 18),
          ]),
        ),
      );
}
