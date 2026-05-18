import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/features/pos/providers/cart_provider.dart';
import 'package:hulu_coffee_pos/core/database/transaction_repository.dart';
import 'package:hulu_coffee_pos/features/orders/transaction_provider.dart';
import 'package:hulu_coffee_pos/features/settings/qris_settings_provider.dart';

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
          'Hulu Coffee — Checkout',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _buildContent(context, cartState, formatCurrency),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, CartState cartState, NumberFormat fmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Order Summary ─────────────────────────────────────────────────
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
                    fmt.format(cartState.subtotal),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.receipt_long,
                      size: 14, color: AppTheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    '${cartState.itemCount} item${cartState.itemCount == 1 ? '' : 's'}',
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

        // ── Payment Method ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04), blurRadius: 20)
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
                      child: _buildMethodItem('QRIS',
                          Icons.qr_code_scanner, selectedMethod == 'QRIS'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => selectedMethod = 'Cash'),
                      borderRadius: BorderRadius.circular(20),
                      child: _buildMethodItem('Cash',
                          Icons.payments_outlined, selectedMethod == 'Cash'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── QRIS Code Display (only when QRIS selected) ───────────────────
        if (selectedMethod == 'QRIS') ...[
          _QrisCodeCard(),
          const SizedBox(height: 24),
        ],

        // ── Confirm Button ────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: () async {
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => Dialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                              color: AppTheme.primary),
                          const SizedBox(height: 24),
                          Text('Processing Payment...',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Please wait a moment',
                              style: TextStyle(
                                  color: AppTheme.onSurfaceVariant
                                      .withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                  ),
                );

                await Future.delayed(const Duration(seconds: 2));

                final repo = ref.read(transactionRepositoryProvider);
                await repo.saveFromCart(cartState,
                    paymentMethod: selectedMethod);
                ref.invalidate(allTransactionsProvider);
                ref.invalidate(todayStatsProvider);
                ref.invalidate(topItemsProvider);

                if (mounted) {
                  Navigator.of(context).pop();
                  context.pushReplacementNamed('payment_success', extra: {
                    'cart': cartState,
                    'paymentMethod': selectedMethod,
                  });
                  ref.read(cartProvider.notifier).clearCart();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Payment failed: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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

  Widget _buildMethodItem(String label, IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryContainer
            : AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? Border.all(
                color: AppTheme.primary.withValues(alpha: 0.5), width: 1.5)
            : Border.all(color: Colors.transparent, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 32,
              color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── QRIS Code Card ────────────────────────────────────────────────────────────
class _QrisCodeCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathAsync = ref.watch(qrisImagePathProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 20)
        ],
      ),
      child: Column(
        children: [
          Text(
            'SCAN TO PAY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 20),
          pathAsync.when(
            loading: () => const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator())),
            error: (_, __) => _noQrPlaceholder(context),
            data: (path) {
              if (path == null || path.isEmpty) {
                return _noQrPlaceholder(context);
              }
              final Widget imageWidget;
              if (kIsWeb) {
                imageWidget = Image.network(path,
                    width: 220, height: 220, fit: BoxFit.contain);
              } else {
                final file = File(path);
                if (!file.existsSync()) return _noQrPlaceholder(context);
                imageWidget = Image.file(file,
                    width: 220, height: 220, fit: BoxFit.contain);
              }
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageWidget,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: AppTheme.primary),
                        SizedBox(width: 6),
                        Text(
                          'Confirm payment after customer scans',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _noQrPlaceholder(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.outlineVariant.withValues(alpha: 0.5),
                width: 2,
                style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_rounded,
                  size: 72,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text('No QR Code configured',
                  style: TextStyle(
                      fontSize: 12,
                      color:
                          AppTheme.onSurfaceVariant.withValues(alpha: 0.6))),
              const SizedBox(height: 4),
              Text('Go to Settings → Payment',
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          AppTheme.onSurfaceVariant.withValues(alpha: 0.4))),
            ],
          ),
        ),
      ],
    );
  }
}
