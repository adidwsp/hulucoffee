import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/shared/models/product_models.dart';
import 'package:hulu_coffee_pos/shared/dummy_data.dart';
import 'package:hulu_coffee_pos/features/pos/providers/cart_provider.dart';

import 'widgets/product_card.dart';
import 'widgets/category_chip.dart';
import 'widgets/cart_summary_pill.dart';

// Simple category provider for filtering
final selectedCategoryProvider = StateProvider<ProductCategory>((ref) => ProductCategory.coffee);
final searchQueryProvider = StateProvider<String>((ref) => '');

class PosHomeScreen extends ConsumerWidget {
  const PosHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

    // Filter products
    final filteredProducts = dummyProducts.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(searchQuery);
      final matchesCategory = p.category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.storefront, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              'Hulu Coffee - Downtown Booth',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primary,
                    fontSize: 16,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi, color: AppTheme.primaryContainer),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
              Container(
                color: AppTheme.surface,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                    decoration: InputDecoration(
                      hintText: 'Search menu items...',
                      hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.onSurfaceVariant),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              
              // Category Chips List
              Container(
                color: AppTheme.surface,
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      CategoryChip(
                        label: 'Coffee',
                        isSelected: selectedCategory == ProductCategory.coffee,
                        onTap: () => ref.read(selectedCategoryProvider.notifier).state = ProductCategory.coffee,
                      ),
                      CategoryChip(
                        label: 'Non-Coffee',
                        isSelected: selectedCategory == ProductCategory.nonCoffee,
                        onTap: () => ref.read(selectedCategoryProvider.notifier).state = ProductCategory.nonCoffee,
                      ),
                      CategoryChip(
                        label: 'Tea',
                        isSelected: selectedCategory == ProductCategory.tea,
                        onTap: () => ref.read(selectedCategoryProvider.notifier).state = ProductCategory.tea,
                      ),
                      CategoryChip(
                        label: 'Snacks',
                        isSelected: selectedCategory == ProductCategory.snacks,
                        onTap: () => ref.read(selectedCategoryProvider.notifier).state = ProductCategory.snacks,
                      ),
                    ],
                  ),
                ),
              ),

              // Product Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // padding bottom for fab
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                        ref.read(cartProvider.notifier).addToCart(product, options: options);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          
          // Cart Summary Pill Overlay
          const CartSummaryPill(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.outline,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
          onTap: (index) {
            if (index == 1) context.pushNamed('queue');
            if (index == 2) context.pushNamed('reports');
            if (index == 3) context.pushNamed('settings');
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale),
              label: 'POS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'QUEUE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'REPORTS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'SETTINGS',
            ),
          ],
        ),
      ),
    );
  }
}
