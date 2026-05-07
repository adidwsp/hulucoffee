import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/features/pos/providers/cart_provider.dart';
import 'package:hulu_coffee_pos/shared/widgets/app_bottom_nav.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const Icon(Icons.coffee_rounded,
          color: AppTheme.outlineVariant, size: 28);
    }
    if (imageUrl.startsWith('data:')) {
      return const Icon(Icons.image_rounded,
          color: AppTheme.outlineVariant, size: 28);
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
        color: AppTheme.outlineVariant, size: 28);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Row(
          children: [
            const Text('My Cart',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            if (cartState.itemCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${cartState.itemCount}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (cartState.items.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
              },
              child: const Text('Clear All',
                  style: TextStyle(color: AppTheme.error)),
            ),
        ],
      ),
      body: cartState.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 72,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.goNamed('home'),
                    icon: const Icon(Icons.point_of_sale_rounded),
                    label: const Text('Go to POS'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartState.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = cartState.items[index];
                      final opts = <String>[];
                      if (item.options.size != 'Regular') {
                        opts.add(item.options.size ?? '');
                      }
                      if (item.options.temperature != 'Iced') {
                        opts.add(item.options.temperature ?? '');
                      }
                      if (item.options.sugarLevel != 'Normal') {
                        opts.add(item.options.sugarLevel ?? '');
                      }
                      if (item.options.selectedAddons.isNotEmpty) {
                        opts.addAll(item.options.selectedAddons);
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
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
                            // Image
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _buildProductImage(item.product.imageUrl),
                            ),
                            const SizedBox(width: 12),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  if (opts.isNotEmpty)
                                    Text(opts.join(' · '),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.onSurfaceVariant
                                                .withValues(alpha: 0.7))),
                                  const SizedBox(height: 4),
                                  Text(fmt.format(item.product.price),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            // Qty controls
                            Row(
                              children: [
                                _QtyBtn(
                                  icon: item.quantity == 1
                                      ? Icons.delete_rounded
                                      : Icons.remove_rounded,
                                  color: item.quantity == 1
                                      ? AppTheme.error
                                      : AppTheme.onSurface,
                                  onTap: () => ref
                                      .read(cartProvider.notifier)
                                      .updateQuantity(
                                          item.id, item.quantity - 1),
                                ),
                                SizedBox(
                                  width: 32,
                                  child: Text('${item.quantity}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                ),
                                _QtyBtn(
                                  icon: Icons.add_rounded,
                                  color: AppTheme.primary,
                                  onTap: () => ref
                                      .read(cartProvider.notifier)
                                      .updateQuantity(
                                          item.id, item.quantity + 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // ── Checkout panel ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -4))
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.onSurfaceVariant)),
                            Text(fmt.format(cartState.subtotal),
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => context.pushNamed('payment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.payment_rounded),
                                const SizedBox(width: 8),
                                Text(
                                    'Proceed to Payment • ${fmt.format(cartState.subtotal)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => context.goNamed('home'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline_rounded),
                                SizedBox(width: 8),
                                Text('Add Another Item',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      );
}
