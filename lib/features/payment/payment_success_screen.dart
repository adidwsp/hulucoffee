import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/core/database/transaction_repository.dart';
import 'package:hulu_coffee_pos/features/orders/transaction_provider.dart';
import 'package:hulu_coffee_pos/features/pos/providers/cart_provider.dart';

class PaymentSuccessScreen extends ConsumerWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          Positioned(
            top: -100, left: -100,
            child: Container(width: 400, height: 400,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppTheme.primaryFixedDim.withValues(alpha: 0.2))),
          ),
          Positioned(
            bottom: -150, right: -150,
            child: Container(width: 400, height: 400,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppTheme.secondaryFixed.withValues(alpha: 0.2))),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 32, offset: const Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96, height: 96,
                      decoration: const BoxDecoration(color: AppTheme.secondaryContainer, shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle_rounded, color: AppTheme.onSecondaryContainer, size: 52),
                    ),
                    const SizedBox(height: 24),
                    Text('Payment Successful',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text('Transaction has been saved.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        children: [
                          Text('TOTAL PAID',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.onSurfaceVariant, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(fmt.format(cartState.subtotal),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900, color: AppTheme.primary)),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text('${cartState.itemCount} item${cartState.itemCount == 1 ? '' : 's'} • QRIS',
                            style: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: () async {
                          // Save transaction then clear cart
                          final repo = ref.read(transactionRepositoryProvider);
                          await repo.saveFromCart(cartState);
                          ref.invalidate(allTransactionsProvider);
                          ref.invalidate(todayStatsProvider);
                          ref.read(cartProvider.notifier).clearCart();
                          if (context.mounted) context.goNamed('home');
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('New Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.onSurface,
                          side: const BorderSide(color: AppTheme.outlineVariant),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: () => context.goNamed('history'),
                        icon: const Icon(Icons.history_rounded),
                        label: const Text('View History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
