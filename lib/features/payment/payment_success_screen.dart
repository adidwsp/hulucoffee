import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/features/pos/providers/cart_provider.dart';

class PaymentSuccessScreen extends ConsumerWidget {
  final CartState? cartState;
  final String? paymentMethod;

  const PaymentSuccessScreen({super.key, this.cartState, this.paymentMethod});

  Future<void> _printReceipt(CartState state) async {
    final doc = pw.Document();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                  child: pw.Text('Hulu Coffee',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Center(
                  child: pw.Text('Receipt',
                      style: const pw.TextStyle(fontSize: 16))),
              pw.SizedBox(height: 10),
              pw.Divider(),
              ...state.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                            child: pw.Text(
                                '${item.quantity}x ${item.product.name}')),
                        pw.Text(fmt.format(item.totalPrice)),
                      ]),
                );
              }),
              pw.Divider(),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(fmt.format(state.subtotal),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ]),
              pw.SizedBox(height: 8),
              pw.Text('Payment: ${paymentMethod ?? 'QRIS'}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Thank you for your visit!')),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the passed cart state, or fallback to the provider (which might be empty)
    final CartState currentState = cartState ?? ref.watch(cartProvider);
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
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 96, height: 96,
                          decoration: const BoxDecoration(color: AppTheme.secondaryContainer, shape: BoxShape.circle),
                          child: const Icon(Icons.check_circle_rounded, color: AppTheme.onSecondaryContainer, size: 52),
                        ),
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
                            Text(fmt.format(currentState.subtotal),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900, color: AppTheme.primary)),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text('${currentState.itemCount} item${currentState.itemCount == 1 ? '' : 's'} • ${paymentMethod ?? 'QRIS'}',
                              style: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 13)),
                          ],
                        ),
                      ),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: () async {
                          // Cart was already saved and cleared in the previous screen
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
                        onPressed: () => _printReceipt(currentState),
                        icon: const Icon(Icons.print_rounded),
                        label: const Text('Print Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.onSurfaceVariant,
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
          ),
        ],
      ),
    );
  }
}
