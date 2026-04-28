import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/features/pos/providers/product_provider.dart';
import 'package:hulu_coffee_pos/shared/models/product_models.dart';
import 'package:intl/intl.dart';

import 'widgets/product_form_dialog.dart';

// State providers for filtering
final menuSearchQueryProvider = StateProvider<String>((ref) => '');
final menuSelectedCategoryProvider =
    StateProvider<ProductCategory>((ref) => ProductCategory.all);

class MenuManagementScreen extends ConsumerWidget {
  const MenuManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productNotifierProvider);
    final formatCurrency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final selectedCategory = ref.watch(menuSelectedCategoryProvider);
    final searchQuery = ref.watch(menuSearchQueryProvider).toLowerCase();

    final filteredProducts = productsAsync.when(
      data: (products) => products.where((p) {
        final matchesSearch = p.name.toLowerCase().contains(searchQuery);
        final matchesCategory = selectedCategory == ProductCategory.all ||
            p.category == selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList(),
      loading: () => <Product>[],
      error: (_, __) => <Product>[],
    );

    // Responsive breakpoints
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    if (screenWidth > 1200) {
      crossAxisCount = 3;
    } else if (screenWidth > 800) {
      crossAxisCount = 2;
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Hulu Coffee',
            style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
                letterSpacing: -0.5)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Menu Management',
                            style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                                letterSpacing: -0.5)),
                        SizedBox(height: 8),
                        Text(
                            'Control availability, edit items, or add new seasonal offerings.',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const ProductFormDialog(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Controls Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) => ref
                          .read(menuSearchQueryProvider.notifier)
                          .state = value,
                      decoration: InputDecoration(
                        hintText: 'Search menu items...',
                        prefixIcon:
                            const Icon(Icons.search, color: AppTheme.outline),
                        filled: true,
                        fillColor: AppTheme.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip(context, ref, 'All Categories',
                              ProductCategory.all),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                              context, ref, 'Espresso', ProductCategory.coffee),
                          const SizedBox(width: 8),
                          _buildFilterChip(context, ref, 'Cold Brew',
                              ProductCategory.nonCoffee),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                              context, ref, 'Tea', ProductCategory.tea),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                              context, ref, 'Pastries', ProductCategory.snacks),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Product Grid
              Expanded(
                child: productsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                  data: (_) {
                    if (filteredProducts.isEmpty) {
                      return const Center(child: Text('No products found.'));
                    }
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return _buildProductCard(
                            context, ref, product, formatCurrency);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String label,
      ProductCategory category) {
    final selectedCategory = ref.watch(menuSelectedCategoryProvider);
    final isSelected = selectedCategory == category;

    return ActionChip(
      label: Text(label),
      backgroundColor:
          isSelected ? AppTheme.secondaryContainer : AppTheme.surface,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.onSecondaryContainer : AppTheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected
            ? Colors.transparent
            : AppTheme.outlineVariant.withOpacity(0.5),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      onPressed: () {
        ref.read(menuSelectedCategoryProvider.notifier).state = category;
      },
    );
  }

  Widget _buildProductCard(BuildContext context, WidgetRef ref, Product product,
      NumberFormat formatCurrency) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.surfaceVariant,
                  image: DecorationImage(
                    image: NetworkImage(product.imageUrl),
                    fit: BoxFit.cover,
                    colorFilter: product.isAvailable
                        ? null
                        : const ColorFilter.mode(
                            Colors.grey, BlendMode.saturation),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency.format(product.price),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: product.isAvailable
                          ? AppTheme.onSurface
                          : AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.isAvailable
                          ? AppTheme.secondaryContainer
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.category.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: product.isAvailable
                            ? AppTheme.onSecondaryContainer
                            : AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: product.isAvailable
                        ? AppTheme.onSurface
                        : AppTheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Switch(
                    value: product.isAvailable,
                    onChanged: (val) {
                      ref
                          .read(productNotifierProvider.notifier)
                          .toggleAvailability(product);
                    },
                    activeThumbColor: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    product.isAvailable ? 'AVAILABLE' : 'OUT OF STOCK',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: product.isAvailable
                          ? AppTheme.primary
                          : AppTheme.error,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ProductFormDialog(product: product),
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
