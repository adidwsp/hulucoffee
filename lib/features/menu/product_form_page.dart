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
import 'package:hulu_coffee_pos/features/menu/customization_option_provider.dart';
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
  List<String> _enabledOptions = [];
  Map<String, double> _optionPriceOverrides = {};

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
    _enabledOptions = p?.enabledOptions.toList() ?? [];
    _optionPriceOverrides = Map.from(p?.optionPriceOverrides ?? {});
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
        optionPriceOverrides: _optionPriceOverrides,
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
              ref.watch(customizationOptionProvider).when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                    data: (allOptions) {
                      return Column(
                        children: OptionType.all.map((type) {
                          final isEnabled = _enabledOptions.contains(type);
                          final typeOptions =
                              allOptions.where((o) => o.type == type).toList();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AppTheme.outlineVariant),
                            ),
                            child: Theme(
                              data: Theme.of(context)
                                  .copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                leading: Switch(
                                  value: isEnabled,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val)
                                        _enabledOptions.add(type);
                                      else
                                        _enabledOptions.remove(type);
                                    });
                                  },
                                  activeThumbColor: AppTheme.primary,
                                ),
                                title: Text(OptionType.displayName(type),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                subtitle: Text(
                                    isEnabled
                                        ? '${typeOptions.length} options enabled'
                                        : 'Disabled',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.onSurfaceVariant)),
                                children: [
                                  const Divider(
                                      height: 1,
                                      color: AppTheme.outlineVariant),
                                  if (typeOptions.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text('No options available.',
                                          style: TextStyle(
                                              color: AppTheme.outline)),
                                    ),
                                  ...typeOptions.map((opt) {
                                    final currentVal =
                                        _optionPriceOverrides[opt.id] ?? 0;
                                    return Container(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                            bottom: BorderSide(
                                                color:
                                                    AppTheme.outlineVariant)),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(opt.label,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13)),
                                                Text(
                                                    'Default: Rp ${opt.priceModifier.toInt()}',
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppTheme
                                                            .onSurfaceVariant)),
                                              ],
                                            ),
                                          ),
                                          if (isEnabled) ...[
                                            SizedBox(
                                              width: 90,
                                              height: 36,
                                              child: TextFormField(
                                                initialValue: currentVal > 0
                                                    ? currentVal
                                                        .toInt()
                                                        .toString()
                                                    : '',
                                                decoration: InputDecoration(
                                                  hintText: 'Override',
                                                  prefixText: 'Rp ',
                                                  hintStyle: const TextStyle(
                                                      fontSize: 11),
                                                  prefixStyle: const TextStyle(
                                                      fontSize: 11),
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 0),
                                                  border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6)),
                                                ),
                                                style: const TextStyle(
                                                    fontSize: 12),
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly
                                                ],
                                                onChanged: (v) {
                                                  final val =
                                                      double.tryParse(v) ?? 0;
                                                  setState(() {
                                                    if (val > 0)
                                                      _optionPriceOverrides[
                                                          opt.id] = val;
                                                    else
                                                      _optionPriceOverrides
                                                          .remove(opt.id);
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          IconButton(
                                            icon: const Icon(Icons.edit_rounded,
                                                size: 16,
                                                color: AppTheme.primary),
                                            onPressed: () =>
                                                _showEditOptionDialog(
                                                    context, ref, opt),
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(8),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_rounded,
                                                size: 16,
                                                color: AppTheme.error),
                                            onPressed: () => _deleteOption(opt),
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(8),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextButton.icon(
                                      onPressed: () => _showAddOptionDialog(
                                          context, ref, type),
                                      icon: const Icon(Icons.add_rounded,
                                          size: 18),
                                      label: const Text('Add Option'),
                                      style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
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

  void _showAddOptionDialog(BuildContext context, WidgetRef ref, String type) {
    final labelCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add ${OptionType.displayName(type)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              autofocus: true,
              decoration:
                  const InputDecoration(labelText: 'Label (e.g. Large)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: subtitleCtrl,
              decoration:
                  const InputDecoration(labelText: 'Subtitle (optional)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              decoration:
                  const InputDecoration(labelText: 'Price modifier (Rp)'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (labelCtrl.text.trim().isNotEmpty) {
                ref.read(customizationOptionProvider.notifier).add(
                      type: type,
                      label: labelCtrl.text.trim(),
                      subtitle: subtitleCtrl.text.trim(),
                      priceModifier: double.tryParse(priceCtrl.text) ?? 0,
                    );
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditOptionDialog(
      BuildContext context, WidgetRef ref, CustomizationOption opt) {
    final labelCtrl = TextEditingController(text: opt.label);
    final subtitleCtrl = TextEditingController(text: opt.subtitle);
    final priceCtrl =
        TextEditingController(text: opt.priceModifier.toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Option'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: subtitleCtrl,
              decoration:
                  const InputDecoration(labelText: 'Subtitle (optional)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              decoration:
                  const InputDecoration(labelText: 'Price modifier (Rp)'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (labelCtrl.text.trim().isNotEmpty) {
                ref
                    .read(customizationOptionProvider.notifier)
                    .updateOption(opt.copyWith(
                      label: labelCtrl.text.trim(),
                      subtitle: subtitleCtrl.text.trim(),
                      priceModifier: double.tryParse(priceCtrl.text) ?? 0,
                    ));
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOption(CustomizationOption opt) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Option'),
        content: Text('Delete "${opt.label}"?'),
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
    if (ok == true) {
      ref.read(customizationOptionProvider.notifier).deleteOption(opt.id);
      setState(() {
        _optionPriceOverrides.remove(opt.id);
      });
    }
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
