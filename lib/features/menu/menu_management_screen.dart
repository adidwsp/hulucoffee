import 'package:flutter/material.dart';
import 'package:hulu_coffee_pos/core/config/theme.dart';

class MenuManagementScreen extends StatelessWidget {
  const MenuManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuItem(context, 'Iced Latte', 'Rp 65.000', true),
          const SizedBox(height: 12),
          _buildMenuItem(context, 'Americano', 'Rp 50.000', true),
          const SizedBox(height: 12),
          _buildMenuItem(context, 'Cold Brew', 'Rp 55.000', false),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, String price, bool isAvailable) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainerHighest),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(price, style: const TextStyle(color: AppTheme.outline)),
            ],
          ),
          Switch(
            value: isAvailable,
            onChanged: (val) {},
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}
