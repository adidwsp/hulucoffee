import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/features/menu/category_provider.dart';
import 'package:hulu_coffee_pos/features/pos/providers/product_provider.dart';
import 'package:hulu_coffee_pos/features/pos/providers/cart_provider.dart';
import 'package:hulu_coffee_pos/features/pos/providers/sort_provider.dart';
import 'package:hulu_coffee_pos/shared/models/product_models.dart';
import 'package:hulu_coffee_pos/shared/widgets/app_header.dart';
import 'package:hulu_coffee_pos/shared/widgets/app_bottom_nav.dart';
import 'widgets/product_card.dart';
import 'widgets/category_chip.dart';
import 'widgets/cart_summary_pill.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'all');
final searchQueryProvider = StateProvider<String>((ref) => '');

class PosHomeScreen extends ConsumerWidget {
  const PosHomeScreen({super.key});

  List<Product> _sortProducts(
    List<Product> products,
    SortMode mode,
    Map<String, Map<String, dynamic>> buyStats,
  ) {
    final sorted = List<Product>.from(products);
    switch (mode) {
      case SortMode.nameAsc:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortMode.mostBought:
        sorted.sort((a, b) {
          final aQty = (buyStats[a.name]?['totalQty'] as int?) ?? 0;
          final bQty = (buyStats[b.name]?['totalQty'] as int?) ?? 0;
          if (bQty != aQty) return bQty.compareTo(aQty);
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case SortMode.latestBought:
        sorted.sort((a, b) {
          final aDate = buyStats[a.name]?['lastBoughtAt'] as DateTime?;
          final bDate = buyStats[b.name]?['lastBoughtAt'] as DateTime?;
          if (aDate == null && bDate == null) {
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
        break;
    }
    return sorted;
  }

  String _sortLabel(SortMode mode) {
    switch (mode) {
      case SortMode.nameAsc:
        return 'Name A–Z';
      case SortMode.mostBought:
        return 'Most Bought';
      case SortMode.latestBought:
        return 'Latest Bought';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
    final productsAsync = ref.watch(productNotifierProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final sortMode = ref.watch(sortModeProvider);
    final buyStatsAsync = ref.watch(productBuyStatsProvider);

    final buyStats = buyStatsAsync.whenOrNull(data: (d) => d) ?? {};

    final filteredProducts = productsAsync.when(
      data: (products) {
        final filtered = products.where((p) {
          final matchesSearch = p.name.toLowerCase().contains(searchQuery);
          final matchesCategory =
              selectedCategory == 'all' || p.category == selectedCategory;
          return matchesSearch && matchesCategory && p.isAvailable;
        }).toList();
        return _sortProducts(filtered, sortMode, buyStats);
      },
      loading: () => <Product>[],
      error: (_, __) => <Product>[],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.goNamed('dashboard');
      },
      child: Scaffold(
        backgroundColor: AppTheme.surfaceContainerLow,
        appBar: const AppHeader(),
        body: Stack(
          children: [
            Column(
              children: [
                // ── Search Bar + Sort ──────────────────────────────────────
                Container(
                  color: AppTheme.surface,
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) =>
                              ref.read(searchQueryProvider.notifier).state = v,
                          decoration: InputDecoration(
                            hintText: 'Search menu items...',
                            hintStyle: TextStyle(
                                color: AppTheme.onSurfaceVariant
                                    .withValues(alpha: 0.5)),
                            prefixIcon: const Icon(Icons.search,
                                color: AppTheme.onSurfaceVariant),
                            filled: true,
                            fillColor: AppTheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<SortMode>(
                        icon: const Icon(Icons.sort_rounded,
                            color: AppTheme.onSurfaceVariant),
                        tooltip: 'Sort by',
                        onSelected: (mode) =>
                            ref.read(sortModeProvider.notifier).state = mode,
                        itemBuilder: (_) => SortMode.values
                            .map((m) => PopupMenuItem(
                                  value: m,
                                  child: Row(
                                    children: [
                                      if (m == sortMode)
                                        const Icon(Icons.check_rounded,
                                            size: 18, color: AppTheme.primary)
                                      else
                                        const SizedBox(width: 18),
                                      const SizedBox(width: 8),
                                      Text(_sortLabel(m)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),

                // ── Category Chips ──────────────────────────────────────────
                Container(
                  color: AppTheme.surface,
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    height: 40,
                    child: categoriesAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (cats) => ListView(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          CategoryChip(
                            label: 'All',
                            isSelected: selectedCategory == 'all',
                            onTap: () => ref
                                .read(selectedCategoryProvider.notifier)
                                .state = 'all',
                          ),
                          ...cats.map((cat) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: CategoryChip(
                                  label: cat.displayName,
                                  isSelected:
                                      selectedCategory == cat.name,
                                  onTap: () => ref
                                      .read(
                                          selectedCategoryProvider.notifier)
                                      .state = cat.name,
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Product Grid ────────────────────────────────────────────
                Expanded(
                  child: productsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                        child: Text('Error loading products: $error',
                            textAlign: TextAlign.center)),
                    data: (_) => filteredProducts.isEmpty
                        ? const Center(child: Text('No items found'))
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.65,
                            ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return ProductCard(
                                product: product,
                                onAdd: (options) {
                                  ref
                                      .read(cartProvider.notifier)
                                      .addToCart(product, options: options);
                                  context.pushNamed('cart');
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
            const CartSummaryPill(),
          ],
        ),
        bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      ),
    );
  }
}
