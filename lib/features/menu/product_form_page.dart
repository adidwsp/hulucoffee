import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/features/menu/category_provider.dart';
import 'package:hulu_coffee_pos/features/pos/providers/product_provider.dart';
import 'package:hulu_coffee_pos/shared/models/customization_option_model.dart';
import 'package:hulu_coffee_pos/shared/models/product_models.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  final Product? product;
  const ProductFormPage({super.key, this.product});

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  String _imagePath = '';
  String _selectedCategory = 'coffee';
  bool _isAvailable = true;
  bool _saving = false;
  List<String> _enabledOptions = [
    OptionType.size,
    OptionType.temperature,
    OptionType.sugarLevel,
    OptionType.addon,
  ];

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(
        text: p != null ? p.price.toInt().toString() : '');
    _imagePath = p?.imageUrl ?? '';
    _selectedCategory = p?.category ?? 'coffee';
    _isAvailable = p?.isAvailable ?? true;
    _enabledOptions = p?.enabledOptions.toList() ??
        [
          OptionType.size,
          OptionType.temperature,
          OptionType.sugarLevel,
          OptionType.addon,
        ];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // ── Image picker ─────────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      final b64 = base64Encode(bytes);
      setState(() => _imagePath = 'data:image/jpeg;base64,$b64');
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      final imgDir = Directory(p.join(docsDir.path, 'product_images'));
      await imgDir.create(recursive: true);
      final fileName = '${const Uuid().v4()}.jpg';
      final targetPath = p.join(imgDir.path, fileName);

      final compressed = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        targetPath,
        quality: 75,
        minWidth: 400,
        minHeight: 400,
      );
      setState(() => _imagePath = compressed?.path ?? picked.path);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppTheme.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: AppTheme.primary),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Image display ────────────────────────────────────────────────────────────
  Widget _buildImagePreview() {
    if (_imagePath.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_rounded,
              size: 48,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text('Tap to add photo',
              style: TextStyle(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontSize: 13)),
        ],
      );
    }
    if (_imagePath.startsWith('data:')) {
      final data = _imagePath.substring(_imagePath.indexOf(',') + 1);
      return Image.memory(base64Decode(data),
          fit: BoxFit.cover, width: double.infinity);
    }
    if (_imagePath.startsWith('http')) {
      return Image.network(_imagePath,
          fit: BoxFit.cover, width: double.infinity);
    }
    return Image.file(File(_imagePath),
        fit: BoxFit.cover, width: double.infinity);
  }

  // ── Save ─────────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final product = Product(
        id: widget.product?.id ?? const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text),
        imageUrl: _imagePath,
        category: _selectedCategory,
        isAvailable: _isAvailable,
        enabledOptions: _enabledOptions,
      );
      final notifier = ref.read(productNotifierProvider.notifier);
      if (_isEdit) {
        await notifier.updateProduct(product);
      } else {
        await notifier.addProduct(product);
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────────
  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content:
            Text('Delete "${widget.product!.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref
        .read(productNotifierProvider.notifier)
        .deleteProduct(widget.product!.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(
            _isEdit ? 'Edit Item' : 'Add New Item',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            if (_isEdit)
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: AppTheme.error),
                onPressed: _delete,
                tooltip: 'Delete item',
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Image picker ───────────────────────────────────────────────
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.outlineVariant,
                        style: BorderStyle.solid),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Center(child: _buildImagePreview()),
                      if (_imagePath.isNotEmpty)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_rounded,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Change',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Name ───────────────────────────────────────────────────────
              const _FieldLabel('Product Name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDeco('e.g. Iced Latte'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),

              const SizedBox(height: 16),

              // ── Price ──────────────────────────────────────────────────────
              const _FieldLabel('Price (Rp)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _priceCtrl,
                decoration: _inputDeco('e.g. 35000'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Price is required';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Category ───────────────────────────────────────────────────
              const _FieldLabel('Category'),
              const SizedBox(height: 6),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Failed to load categories'),
                data: (cats) => DropdownButtonFormField<String>(
                  initialValue: cats.any((c) => c.name == _selectedCategory)
                      ? _selectedCategory
                      : cats.first.name,
                  decoration: _inputDeco(null),
                  items: cats
                      .map((c) => DropdownMenuItem(
                            value: c.name,
                            child: Text(c.displayName),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCategory = v);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ── Description ────────────────────────────────────────────────
              const _FieldLabel('Description'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                decoration: _inputDeco('Short description of the item'),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // ── Customization Options ──────────────────────────────────
              const _FieldLabel('Customization Options'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Enable for this product:',
                        style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                      ),
                    ),
                    ...[
                      (OptionType.size, Icons.straighten_rounded, 'Size (Small/Medium/Large)'),
                      (OptionType.temperature, Icons.thermostat_rounded, 'Temperature (Hot/Iced)'),
                      (OptionType.sugarLevel, Icons.water_drop_rounded, 'Sugar Level'),
                      (OptionType.addon, Icons.add_circle_rounded, 'Add-ons (Extra Shot, etc.)'),
                    ].map((entry) {
                      final (type, icon, label) = entry;
                      final isEnabled = _enabledOptions.contains(type);
                      return InkWell(
                        onTap: () => setState(() {
                          if (isEnabled) {
                            _enabledOptions.remove(type);
                          } else {
                            _enabledOptions.add(type);
                          }
                        }),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(icon,
                                  size: 18,
                                  color: isEnabled
                                      ? AppTheme.primary
                                      : AppTheme.outlineVariant),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(label,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isEnabled
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isEnabled
                                            ? AppTheme.onSurface
                                            : AppTheme.onSurfaceVariant)),
                              ),
                              Switch(
                                value: isEnabled,
                                onChanged: (val) => setState(() {
                                  if (val) {
                                    _enabledOptions.add(type);
                                  } else {
                                    _enabledOptions.remove(type);
                                  }
                                }),
                                activeThumbColor: AppTheme.primary,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Availability ───────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outlineVariant),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available for Order',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    _isAvailable ? 'Visible in POS menu' : 'Hidden from menu',
                    style: TextStyle(
                        color: _isAvailable ? AppTheme.primary : AppTheme.error,
                        fontSize: 12),
                  ),
                  value: _isAvailable,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (v) => setState(() => _isAvailable = v),
                ),
              ),

              const SizedBox(height: 32),

              // ── Save button ────────────────────────────────────────────────
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _isEdit ? 'Save Changes' : 'Add Product',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                ),
              ),

              if (_isEdit) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon:
                        const Icon(Icons.delete_rounded, color: AppTheme.error),
                    label: const Text('Delete Item',
                        style: TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String? hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppTheme.onSurface),
      );
}
