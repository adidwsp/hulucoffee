import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/core/database/transaction_repository.dart';
import 'package:hulu_coffee_pos/features/orders/transaction_provider.dart';
import 'package:hulu_coffee_pos/shared/models/transaction_model.dart';
import 'package:hulu_coffee_pos/shared/models/product_models.dart';
import 'package:hulu_coffee_pos/features/pos/providers/product_provider.dart';
import 'package:hulu_coffee_pos/shared/widgets/app_bottom_nav.dart';

final _monthFilterProvider = StateProvider<DateTime>((ref) => DateTime.now());

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterMonth = ref.watch(_monthFilterProvider);
    final txAsync = ref.watch(transactionsByMonthProvider(filterMonth));
    final monthFmt = DateFormat('MMMM yyyy');

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppTheme.primary,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primary, AppTheme.primaryContainer],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Transaction History',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('Completed orders by month',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13)),
                        ]),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () {
                        ref.read(_monthFilterProvider.notifier).update((state) =>
                            DateTime(state.year, state.month - 1, 1));
                      },
                    ),
                    Text(
                      monthFmt.format(filterMonth),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () {
                        ref.read(_monthFilterProvider.notifier).update((state) =>
                            DateTime(state.year, state.month + 1, 1));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: txAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (txList) {
            Widget content;
            if (txList.isEmpty) {
              content = ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: _EmptyState(),
                  ),
                ],
              );
            } else {
              // Group by day string 'yyyy-MM-dd'
              final Map<String, List<Transaction>> grouped = {};
              for (var tx in txList) {
                final dayKey = DateFormat('yyyy-MM-dd').format(tx.createdAt);
                if (!grouped.containsKey(dayKey)) grouped[dayKey] = [];
                grouped[dayKey]!.add(tx);
              }

              final sortedDays = grouped.keys.toList()
                ..sort((a, b) => b.compareTo(a)); // Descending

              content = ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: sortedDays.length,
                itemBuilder: (context, i) {
                  final dayKey = sortedDays[i];
                  final dayTx = grouped[dayKey]!;
                  final dayTotal = dayTx.fold<double>(0, (sum, tx) => sum + tx.total);
                  final currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header for the day
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('EEEE, d MMM yyyy').format(dayTx.first.createdAt),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(currencyFmt.format(dayTotal),
                                style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 16)),
                          ],
                        ),
                      ),
                      ...dayTx.map((tx) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TxCard(tx: tx),
                          )),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allTransactionsProvider);
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: content,
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}

class _TxCard extends ConsumerWidget {
  final Transaction tx;
  const _TxCard({required this.tx});

  Future<void> _printReceipt(BuildContext context, Transaction tx) async {
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
              pw.Text('Order: ${tx.orderNumber}'),
              pw.Text('Date: ${DateFormat('d MMM yyyy HH:mm').format(tx.createdAt)}'),
              pw.Divider(),
              ...tx.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                            child: pw.Text(
                                '${item['qty']}x ${item['name']}')),
                        pw.Text(fmt.format(item['total'])),
                      ]),
                );
              }),
              pw.Divider(),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(fmt.format(tx.total),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ]),
              pw.SizedBox(height: 8),
              pw.Text('Payment: ${tx.paymentMethod}',
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

  void _showOrderDetail(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order ${tx.orderNumber}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...tx.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text('${item['qty']}x',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item['name'] as String? ?? '')),
                      Text(fmt.format(item['total'])),
                    ],
                  ),
                )),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(fmt.format(tx.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Remove Transaction?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Remove', style: TextStyle(color: AppTheme.error))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(transactionRepositoryProvider).delete(tx.id);
                        _refreshAll(ref);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaction removed')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditTransaction(context, ref);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      _printReceipt(context, tx);
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _refreshAll(WidgetRef ref) {
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(todayTransactionsProvider);
    ref.invalidate(weekTransactionsProvider);
    ref.invalidate(transactionsByMonthProvider);
    ref.invalidate(todayStatsProvider);
    ref.invalidate(topItemsProvider);
  }

  void _showEditTransaction(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditTransactionForm(tx: tx, onSave: () => _refreshAll(ref)),
    );
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final timeFmt = DateFormat('HH:mm');
    final dateFmt = DateFormat('d MMM yyyy');

    return InkWell(
      onTap: () => _showOrderDetail(context, ref),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_rounded,
                  color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(tx.orderNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(fmt.format(tx.total),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: AppTheme.primary)),
                ]),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(
                      '${tx.itemCount} item${tx.itemCount == 1 ? '' : 's'} · ${tx.paymentMethod}',
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              AppTheme.onSurfaceVariant.withValues(alpha: 0.7))),
                  Text(
                      '${dateFmt.format(tx.createdAt)} ${timeFmt.format(tx.createdAt)}',
                      style: TextStyle(
                          fontSize: 11,
                          color:
                              AppTheme.onSurfaceVariant.withValues(alpha: 0.5))),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditTransactionForm extends ConsumerStatefulWidget {
  final Transaction tx;
  final VoidCallback onSave;

  const _EditTransactionForm({required this.tx, required this.onSave});

  @override
  ConsumerState<_EditTransactionForm> createState() => _EditTransactionFormState();
}

class _EditTransactionFormState extends ConsumerState<_EditTransactionForm> {
  late DateTime selectedDate;
  late String paymentMethod;
  late List<Map<String, dynamic>> items;
  final List<TextEditingController> qtyControllers = [];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.tx.createdAt;
    paymentMethod = widget.tx.paymentMethod;
    items = List<Map<String, dynamic>>.from(widget.tx.items);
    for (var item in items) {
      qtyControllers.add(TextEditingController(text: item['qty'].toString()));
    }
  }

  @override
  void dispose() {
    for (var c in qtyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Transaction',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Transaction Date', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      selectedDate.hour,
                      selectedDate.minute,
                    );
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('EEEE, d MMM yyyy').format(selectedDate)),
                    const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: paymentMethod,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: ['QRIS', 'Cash']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => paymentMethod = v);
              },
            ),
            const SizedBox(height: 16),
            const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...List.generate(items.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: productsAsync.when(
                        data: (products) {
                          // Ensure current name is in the list, otherwise add a dummy or fallback to the current name
                          final currentName = items[i]['name'].toString();
                          final hasProduct = products.any((p) => p.name == currentName);
                          final dropdownItems = products.map((p) => DropdownMenuItem(
                            value: p.name,
                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                          )).toList();
                          
                          if (!hasProduct) {
                            dropdownItems.add(DropdownMenuItem(
                              value: currentName,
                              child: Text(currentName, overflow: TextOverflow.ellipsis),
                            ));
                          }
                          
                          return DropdownButtonFormField<String>(
                            value: currentName,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                            items: dropdownItems,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  items[i]['name'] = val;
                                  final p = products.where((p) => p.name == val).firstOrNull;
                                  if (p != null) {
                                    items[i]['price'] = p.price;
                                  }
                                });
                              }
                            },
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => Text(items[i]['name'].toString()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: qtyControllers[i],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Consumer(builder: (context, ref, _) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        // Recalculate total and item count
                        double total = 0;
                        int itemCount = 0;
                        final List<Map<String, dynamic>> updatedItems = [];

                        for (int i = 0; i < items.length; i++) {
                          final name = items[i]['name'].toString();
                          final qty = int.tryParse(qtyControllers[i].text) ?? 0;
                          if (qty <= 0) continue;

                          final oldItem = items[i];
                          final price = (oldItem['price'] as num?)?.toDouble() ?? 0.0;
                          final itemTotal = price * qty;

                          updatedItems.add({
                            'name': name,
                            'qty': qty,
                            'price': price,
                            'total': itemTotal,
                            'options': oldItem['options'],
                          });
                          total += itemTotal;
                          itemCount += qty;
                        }

                        if (updatedItems.isEmpty) {
                           // Maybe show an error or just don't save
                           return;
                        }

                        final updatedTx = Transaction(
                          id: widget.tx.id,
                          orderNumber: widget.tx.orderNumber,
                          createdAt: selectedDate,
                          itemsJson: jsonEncode(updatedItems),
                          total: total,
                          itemCount: itemCount,
                          paymentMethod: paymentMethod,
                        );

                        await ref.read(transactionRepositoryProvider).update(updatedTx);
                        widget.onSave();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit successful')),
                          );
                        }
                      },
                      child: const Text('Save Changes'),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
                color: AppTheme.surfaceContainerHigh, shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_rounded,
                size: 40,
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 16),
          const Text('No Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Complete an order from the POS to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 13)),
        ]),
      ),
    );
  }
}
