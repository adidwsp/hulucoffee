import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/features/menu/category_provider.dart';
import 'package:hulu_coffee_pos/features/menu/customization_option_provider.dart';
import 'package:hulu_coffee_pos/features/pos/providers/product_provider.dart';
import 'package:hulu_coffee_pos/shared/models/category_model.dart';
import 'package:hulu_coffee_pos/shared/models/customization_option_model.dart';
import 'package:hulu_coffee_pos/shared/models/product_models.dart';

final _menuSearchProvider = StateProvider<String>((ref) => '');
final _menuCategoryProvider = StateProvider<String>((ref) => 'all');
final _menuSortProvider = StateProvider<String>((ref) => 'name_asc');

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Menu Management',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          // Add product button (only on Products tab)
          AnimatedBuilder(
            animation: _tabController,
            builder: (_, __) => _tabController.index == 0
                ? IconButton(
                    icon: const Icon(Icons.add_circle_rounded,
                        color: AppTheme.primary, size: 28),
                    onPressed: () => context.pushNamed('product_form'),
                    tooltip: 'Add product',
                  )
                : const SizedBox.shrink(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.outline,
          indicatorColor: AppTheme.primary,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Categories'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ProductsTab(),
          _CategoriesTab(),
        ],
      ),
    );
  }
}

// ── Products Tab ───────────────────────────────────────────────────────────────

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab();

  Widget _productImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const Icon(Icons.coffee_rounded,
          color: AppTheme.outlineVariant, size: 24);
    }
    if (imageUrl.startsWith('data:')) {
      return const Icon(Icons.image_rounded,
          color: AppTheme.outlineVariant, size: 24);
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
    }
    if (!kIsWeb) {
      return Image.file(File(imageUrl),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
    }
    return const Icon(Icons.coffee_rounded,
        color: AppTheme.outlineVariant, size: 24);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final searchQ = ref.watch(_menuSearchProvider).toLowerCase();
    final selectedCat = ref.watch(_menuCategoryProvider);
    final productsAsync = ref.watch(productNotifierProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    final sortMode = ref.watch(_menuSortProvider);

    final filtered = productsAsync.when(
      data: (ps) {
        final list = ps.where((p) {
          final matchSearch = p.name.toLowerCase().contains(searchQ);
          final matchCat = selectedCat == 'all' || p.category == selectedCat;
          return matchSearch && matchCat;
        }).toList();

        list.sort((a, b) {
          if (sortMode == 'name_asc') return a.name.compareTo(b.name);
          if (sortMode == 'name_desc') return b.name.compareTo(a.name);
          if (sortMode == 'price_asc') return a.price.compareTo(b.price);
          if (sortMode == 'price_desc') return b.price.compareTo(a.price);
          return 0;
        });

        return list;
      },
      loading: () => <Product>[],
      error: (_, __) => <Product>[],
    );

    return Column(
      children: [
        // ── Search + filter ────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) =>
                          ref.read(_menuSearchProvider.notifier).state = v,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon:
                            const Icon(Icons.search, color: AppTheme.outline),
                        filled: true,
                        fillColor: AppTheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.sort_rounded,
                          color: AppTheme.outline),
                      tooltip: 'Sort Products',
                      initialValue: ref.read(_menuSortProvider),
                      onSelected: (val) =>
                          ref.read(_menuSortProvider.notifier).state = val,
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(
                            value: 'name_asc', child: Text('Name (A-Z)')),
                        PopupMenuItem(
                            value: 'name_desc', child: Text('Name (Z-A)')),
                        PopupMenuItem(
                            value: 'price_asc',
                            child: Text('Price (Low-High)')),
                        PopupMenuItem(
                            value: 'price_desc',
                            child: Text('Price (High-Low)')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: categoriesAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (cats) => ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                          label: 'All',
                          selected: selectedCat == 'all',
                          onTap: () => ref
                              .read(_menuCategoryProvider.notifier)
                              .state = 'all'),
                      ...cats.map((c) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _FilterChip(
                                label: c.displayName,
                                selected: selectedCat == c.name,
                                onTap: () => ref
                                    .read(_menuCategoryProvider.notifier)
                                    .state = c.name),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // ── Product list ───────────────────────────────────────────────
        Expanded(
          child: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (_) => filtered.isEmpty
                ? const Center(child: Text('No products found'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final product = filtered[i];
                      return Container(
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
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _productImage(product.imageUrl),
                          ),
                          title: Text(product.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fmt.format(product.price),
                                  style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              const SizedBox(height: 2),
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: product.isAvailable
                                        ? AppTheme.secondaryContainer
                                        : AppTheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    product.isAvailable
                                        ? 'AVAILABLE'
                                        : 'OUT OF STOCK',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                        color: product.isAvailable
                                            ? AppTheme.onSecondaryContainer
                                            : AppTheme.onSurfaceVariant),
                                  ),
                                ),
                              ]),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Toggle availability
                              Switch(
                                value: product.isAvailable,
                                onChanged: (_) => ref
                                    .read(productNotifierProvider.notifier)
                                    .toggleAvailability(product),
                                activeThumbColor: AppTheme.primary,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              // Edit
                              IconButton(
                                icon: const Icon(Icons.edit_rounded,
                                    size: 18, color: AppTheme.primary),
                                onPressed: () => context
                                    .pushNamed('product_form', extra: product),
                              ),
                              // Delete
                              IconButton(
                                icon: const Icon(Icons.delete_rounded,
                                    size: 18, color: AppTheme.error),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Product'),
                                      content:
                                          Text('Delete "${product.name}"?'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel')),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          style: TextButton.styleFrom(
                                              foregroundColor: AppTheme.error),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    await ref
                                        .read(productNotifierProvider.notifier)
                                        .deleteProduct(product.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Categories Tab ─────────────────────────────────────────────────────────────

class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Category',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cats) => cats.isEmpty
            ? const Center(child: Text('No categories yet'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final cat = cats[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.label_rounded,
                              color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cat.displayName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              Text(cat.name,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.onSurfaceVariant
                                          .withValues(alpha: 0.6))),
                            ],
                          ),
                        ),
                        if (cat.isBuiltIn)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('BUILT-IN',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: AppTheme.onSurfaceVariant)),
                          ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded,
                              size: 18, color: AppTheme.primary),
                          onPressed: () => _showRenameDialog(context, ref, cat),
                        ),
                        if (!cat.isBuiltIn)
                          IconButton(
                            icon: const Icon(Icons.delete_rounded,
                                size: 18, color: AppTheme.error),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Category'),
                                  content: Text('Delete "${cat.displayName}"?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.error),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                ref
                                    .read(categoryNotifierProvider.notifier)
                                    .delete(cat);
                              }
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'Category name (e.g. Juices)',
              labelText: 'Display Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(categoryNotifierProvider.notifier).add(ctrl.text);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, Category cat) {
    final ctrl = TextEditingController(text: cat.displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Display Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref
                    .read(categoryNotifierProvider.notifier)
                    .rename(cat, ctrl.text);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppTheme.primary : AppTheme.outlineVariant),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : AppTheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12)),
        ),
      );
}
