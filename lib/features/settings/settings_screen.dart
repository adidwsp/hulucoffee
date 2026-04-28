import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/shared/widgets/app_header.dart';
import 'package:hulu_coffee_pos/shared/widgets/app_bottom_nav.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLow,
      appBar: const AppHeader(title: 'Settings'),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('STORE PROFILE',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.outline)),
          const SizedBox(height: 8),
          _buildSettingsCard([
            _buildSettingTile('Store Profile', 'Name, Address, Contact'),
            const Divider(height: 1),
            _buildSettingTile(
              'Menu Management', 
              'Control availability, add/edit items', 
              onTap: () {
                context.pushNamed('menu');
              },
            ),
            const Divider(height: 1),
            _buildSettingTile('Operating Hours', 'Mon-Sun shifts'),
          ]),
          const SizedBox(height: 24),
          const Text('APPLICATION',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.outline)),
          const SizedBox(height: 8),
          _buildSettingsCard([
            _buildSettingTile('Tax Included', 'Yes'),
            const Divider(height: 1),
            _buildSettingTile('Printer Settings', 'Not Connected',
                trailingIcon: Icons.print),
            const Divider(height: 1),
            _buildSettingTile('Help & Support', ''),
          ]),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Sign Out'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingTile(String title, String subtitle,
      {IconData trailingIcon = Icons.chevron_right, VoidCallback? onTap}) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: const TextStyle(color: AppTheme.outline))
          : null,
      trailing: Icon(trailingIcon, color: AppTheme.outlineVariant),
      onTap: onTap,
    );
  }
}
