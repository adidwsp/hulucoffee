import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/features/settings/qris_settings_provider.dart';
import 'package:hulu_coffee_pos/shared/widgets/app_header.dart';
import 'package:hulu_coffee_pos/shared/widgets/app_bottom_nav.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLow,
      appBar: const AppHeader(title: 'Settings'),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── STORE PROFILE ────────────────────────────────────────────────
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
              onTap: () => context.pushNamed('menu'),
            ),
            const Divider(height: 1),
            _buildSettingTile('Operating Hours', 'Mon-Sun shifts'),
          ]),
          const SizedBox(height: 24),

          // ── PAYMENT ──────────────────────────────────────────────────────
          const Text('PAYMENT',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.outline)),
          const SizedBox(height: 8),
          _buildSettingsCard([
            _QrisSettingsTile(),
          ]),
          const SizedBox(height: 24),

          // ── APPLICATION ──────────────────────────────────────────────────
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
      child: Column(children: children),
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

// ── QRIS Upload Tile ──────────────────────────────────────────────────────────
class _QrisSettingsTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathAsync = ref.watch(qrisImagePathProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment QR Code (QRIS)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  SizedBox(height: 2),
                  Text('Shown to customers at checkout',
                      style: TextStyle(color: AppTheme.outline, fontSize: 12)),
                ],
              ),
              pathAsync.whenOrNull(
                    data: (p) => p != null
                        ? TextButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Remove QR Code?'),
                                  content: const Text(
                                      'The QR code will no longer be shown at checkout.'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Remove',
                                            style: TextStyle(
                                                color: AppTheme.error))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                ref.read(qrisImagePathProvider.notifier).clear();
                              }
                            },
                            child: const Text('Remove',
                                style: TextStyle(color: AppTheme.error)),
                          )
                        : null,
                  ) ??
                  const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 16),
          // QR preview
          Center(child: QrisImageWidget(size: 180)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.upload_rounded),
              label: Text(
                pathAsync.whenOrNull(data: (p) => p != null) == true
                    ? 'Replace QR Code'
                    : 'Upload QR Code',
              ),
              onPressed: () async {
                await ref.read(qrisImagePathProvider.notifier).pickAndSave();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('QRIS code updated successfully!')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
