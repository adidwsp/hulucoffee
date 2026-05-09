import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/features/pos/providers/cart_provider.dart';
import 'package:hulu_coffee_pos/core/database/transaction_repository.dart';
import 'package:hulu_coffee_pos/features/orders/transaction_provider.dart';

class QrisPaymentScreen extends ConsumerStatefulWidget {
  const QrisPaymentScreen({super.key});

  @override
  ConsumerState<QrisPaymentScreen> createState() => _QrisPaymentScreenState();
}

class _QrisPaymentScreenState extends ConsumerState<QrisPaymentScreen> {
  String selectedMethod = 'QRIS';

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final formatCurrency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Hulu Coffee - Checkout',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
        ),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 700;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _buildLeftColumn(context, cartState, formatCurrency),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLeftColumn(
      BuildContext context, CartState cartState, NumberFormat formatCurrency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order Summary Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ORDER SUMMARY',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    formatCurrency.format(cartState.subtotal),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.receipt_long,
                      size: 14, color: AppTheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Order #HC-${DateTime.now().millisecond}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Payment Method Selection
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECT PAYMENT METHOD',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => selectedMethod = 'QRIS'),
                      borderRadius: BorderRadius.circular(20),
                      child: _buildPaymentMethodItem(
                        context,
                        label: 'QRIS',
                        icon: Icons.qr_code_scanner,
                        isSelected: selectedMethod == 'QRIS',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => selectedMethod = 'Cash'),
                      borderRadius: BorderRadius.circular(20),
                      child: _buildPaymentMethodItem(
                        context,
                        label: 'Cash',
                        icon: Icons.payments_outlined,
                        isSelected: selectedMethod == 'Cash',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: () async {
              try {
                final repo = ref.read(transactionRepositoryProvider);
                await repo.saveFromCart(cartState,
                    paymentMethod: selectedMethod);
                ref.invalidate(allTransactionsProvider);
                ref.invalidate(todayStatsProvider);
                ref.invalidate(topItemsProvider);

                if (mounted) {
                  context.pushReplacementNamed('payment_success', extra: {
                    'cart': cartState,
                    'paymentMethod': selectedMethod,
                  });
                  ref.read(cartProvider.notifier).clearCart();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to process payment: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Confirm Payment',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodItem(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryContainer
            : AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? Border.all(color: AppTheme.primary.withOpacity(0.5), width: 1.5)
            : Border.all(color: Colors.transparent, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
