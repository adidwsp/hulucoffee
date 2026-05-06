import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/shared/models/product_models.dart';
import 'product_customization_sheet.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final Function(CustomizationOptions) onAdd;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
  });

  Widget _buildImage() {
    final url = product.imageUrl;
    if (url.isEmpty) {
      return Center(
        child: Icon(Icons.coffee_rounded, size: 48,
            color: AppTheme.outlineVariant.withValues(alpha: 0.4)),
      );
    }
    if (url.startsWith('data:')) {
      return Center(
        child: Icon(Icons.image_rounded, size: 48,
            color: AppTheme.outlineVariant.withValues(alpha: 0.4)),
      );
    }
    if (url.startsWith('http')) {
      return Image.network(url, fit: BoxFit.cover, width: double.infinity,
          errorBuilder: (_, __, ___) => Center(
              child: Icon(Icons.broken_image_rounded, size: 40,
                  color: AppTheme.outlineVariant.withValues(alpha: 0.4))));
    }
    if (!kIsWeb) {
      final f = File(url);
      if (f.existsSync()) {
        return Image.file(f, fit: BoxFit.cover, width: double.infinity,
            errorBuilder: (_, __, ___) => Center(
                child: Icon(Icons.coffee_rounded, size: 48,
                    color: AppTheme.outlineVariant.withValues(alpha: 0.4))));
      }
    }
    return Center(
      child: Icon(Icons.coffee_rounded, size: 48,
          color: AppTheme.outlineVariant.withValues(alpha: 0.4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: AppTheme.surfaceContainerHighest,
                  child: _buildImage(),
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(product.description,
                        style: TextStyle(fontSize: 10, letterSpacing: 0.8,
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(fmt.format(product.price),
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        GestureDetector(
                          onTap: product.isAvailable
                              ? () async {
                                  final result =
                                      await showModalBottomSheet<CustomizationOptions>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) =>
                                        ProductCustomizationSheet(product: product),
                                  );
                                  if (result != null && context.mounted) {
                                    onAdd(result);
                                  }
                                }
                              : null,
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: product.isAvailable
                                  ? AppTheme.primary
                                  : AppTheme.surfaceContainerHigh,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.add,
                                size: 18,
                                color: product.isAvailable
                                    ? Colors.white
                                    : AppTheme.outlineVariant),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!product.isAvailable)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('OUT OF STOCK',
                      style: TextStyle(color: Colors.white,
                          fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
