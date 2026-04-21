import 'package:flutter/material.dart';
import 'package:hulu_coffee_pos/core/config/theme.dart';

class OrderQueueScreen extends StatelessWidget {
  const OrderQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQueueColumn(
                    context,
                    title: 'Pending',
                    count: 3,
                    items: [
                      _buildOrderCard(
                        context,
                        orderId: '#042',
                        time: '4m',
                        items: [
                          _OrderItem('Iced Latte', options: ['Oat Milk', 'Extra Shot']),
                          _OrderItem('Cortado'),
                        ],
                        actionLabel: 'Start Preparing',
                        onAction: () {},
                      ),
                      _buildOrderCard(
                        context,
                        orderId: '#043',
                        time: '2m',
                        items: [
                          _OrderItem('Pour Over', options: ['Ethiopia']),
                        ],
                        actionLabel: 'Start Preparing',
                        onAction: () {},
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  _buildQueueColumn(
                    context,
                    title: 'Preparing',
                    count: 2,
                    isActive: true,
                    items: [
                      _buildOrderCard(
                        context,
                        orderId: '#040',
                        time: '6m',
                        isActive: true,
                        items: [
                          _OrderItem('Americano'),
                          _OrderItem('Cappuccino', options: ['Dry']),
                        ],
                        actionLabel: 'Mark as Ready',
                        onAction: () {},
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  _buildQueueColumn(
                    context,
                    title: 'Ready',
                    count: 1,
                    isFaded: true,
                    items: [
                      _buildOrderCard(
                        context,
                        orderId: '#039',
                        time: '10m ago',
                        isDone: true,
                        items: [
                          _OrderItem('Mocha'),
                        ],
                        actionLabel: 'Done (Handed Off)',
                        onAction: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront, color: AppTheme.primary),
              const SizedBox(width: 12),
              Text(
                'Hulu Coffee - Downtown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const Icon(Icons.sensors, color: AppTheme.primary),
        ],
      ),
    );
  }

  Widget _buildQueueColumn(
    BuildContext context, {
    required String title,
    required int count,
    required List<Widget> items,
    bool isActive = false,
    bool isFaded = false,
  }) {
    return Opacity(
      opacity: isFaded ? 0.6 : 1.0,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context, {
    required String orderId,
    required String time,
    required List<_OrderItem> items,
    required String actionLabel,
    required VoidCallback onAction,
    bool isActive = false,
    bool isDone = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isActive)
            Positioned(
              left: -20,
              top: -20,
              bottom: -20,
              child: Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    orderId,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isDone ? AppTheme.outline : AppTheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDone ? Colors.transparent : (isActive ? AppTheme.primaryContainer.withOpacity(0.2) : AppTheme.error.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: isDone ? AppTheme.outline : (isActive ? AppTheme.primaryContainer : AppTheme.error),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? AppTheme.outline : AppTheme.onSurface,
                      ),
                    ),
                    if (item.options != null && item.options!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Wrap(
                          spacing: 8,
                          children: item.options!.map((opt) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              opt,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )).toList(),
                        ),
                      ),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? AppTheme.primary : AppTheme.surfaceContainerHighest,
                    foregroundColor: isActive ? Colors.white : AppTheme.onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(actionLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderItem {
  final String name;
  final List<String>? options;

  _OrderItem(this.name, {this.options});
}
