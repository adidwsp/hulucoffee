import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

const _kQrisKey = 'qris_image_path';

// ── Provider ─────────────────────────────────────────────────────────────────
final qrisImagePathProvider =
    AsyncNotifierProvider<QrisImageNotifier, String?>(QrisImageNotifier.new);

class QrisImageNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kQrisKey);
  }

  Future<void> pickAndSave() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kQrisKey, picked.path);
    state = AsyncData(picked.path);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kQrisKey);
    state = const AsyncData(null);
  }
}

/// Helper widget: shows the QRIS image or a placeholder
class QrisImageWidget extends StatelessWidget {
  final double size;
  const QrisImageWidget({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final pathAsync = ref.watch(qrisImagePathProvider);
        return pathAsync.when(
          loading: () => SizedBox(
            width: size,
            height: size,
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => _placeholder(size),
          data: (path) {
            if (path == null || path.isEmpty) return _placeholder(size);
            final Widget imageWidget;
            if (kIsWeb) {
              imageWidget = Image.network(
                path,
                width: size,
                height: size,
                fit: BoxFit.contain,
              );
            } else {
              final file = File(path);
              if (!file.existsSync()) return _placeholder(size);
              imageWidget = Image.file(
                file,
                width: size,
                height: size,
                fit: BoxFit.contain,
              );
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageWidget,
            );
          },
        );
      },
    );
  }

  Widget _placeholder(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_rounded,
                size: size * 0.45, color: const Color(0xFFBDBDBD)),
            const SizedBox(height: 8),
            Text('No QR Code set',
                style: TextStyle(
                    fontSize: size * 0.07, color: const Color(0xFF9E9E9E))),
          ],
        ),
      );
}
