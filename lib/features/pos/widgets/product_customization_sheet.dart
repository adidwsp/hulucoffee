import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/shared/models/product_models.dart';
import 'package:hulu_coffee_pos/shared/models/customization_option_model.dart';
import 'package:hulu_coffee_pos/features/menu/customization_option_provider.dart';

class ProductCustomizationSheet extends ConsumerStatefulWidget {
  final Product product;
  const ProductCustomizationSheet({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductCustomizationSheet> createState() =>
      _ProductCustomizationSheetState();
}

class _ProductCustomizationSheetState
    extends ConsumerState<ProductCustomizationSheet> {
  // Selected values and their prices
  String? selectedSize;
  double selectedSizePrice = 0;

  String? selectedTemp;
  double selectedTempPrice = 0;

  String? selectedSugar;
  double selectedSugarPrice = 0;

  final Set<String> selectedAddonIds = {};
  double _addonsTotal = 0;

  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double _getEffectivePrice(CustomizationOption opt) {
    // Priority: Product-specific override > Global default
    return widget.product.optionPriceOverrides[opt.id] ?? opt.priceModifier;
  }

  void _recalcAddons(List<CustomizationOption> addons) {
    _addonsTotal = addons
        .where((a) => selectedAddonIds.contains(a.id))
        .fold(0.0, (sum, a) => sum + _getEffectivePrice(a));
  }

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final p = widget.product;

    final sizesAsync = p.hasSize ? ref.watch(activeSizesProvider) : null;
    final tempsAsync =
        p.hasTemperature ? ref.watch(activeTemperaturesProvider) : null;
    final sugarsAsync =
        p.hasSugarLevel ? ref.watch(activeSugarLevelsProvider) : null;
    final addonsAsync = p.hasAddon ? ref.watch(activeAddonsProvider) : null;

    // Set sensible defaults on first build
    sizesAsync?.whenData((sizes) {
      if (selectedSize == null && sizes.isNotEmpty) {
        final match = sizes.where((s) => s.label == 'Small');
        final def = match.isNotEmpty ? match.first : sizes.first;
        selectedSize = def.label;
        selectedSizePrice = _getEffectivePrice(def);
      }
    });
    tempsAsync?.whenData((temps) {
      if (selectedTemp == null && temps.isNotEmpty) {
        final match = temps.where((t) => t.label == 'Iced');
        final def = match.isNotEmpty ? match.first : temps.first;
        selectedTemp = def.label;
        selectedTempPrice = _getEffectivePrice(def);
      }
    });
    sugarsAsync?.whenData((sugars) {
      if (selectedSugar == null && sugars.isNotEmpty) {
        final match = sugars.where((s) => s.label == 'Normal');
        final def = match.isNotEmpty ? match.first : sugars.first;
        selectedSugar = def.label;
        selectedSugarPrice = _getEffectivePrice(def);
      }
    });

    final addons = addonsAsync?.valueOrNull ?? [];
    final totalModifier = selectedSizePrice +
        selectedTempPrice +
        selectedSugarPrice +
        _addonsTotal;
    final totalPrice = p.price + totalModifier;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Product Header ─────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.coffee,
                              size: 40, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900)),
                              Text(p.description,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.onSurfaceVariant)),
                              const SizedBox(height: 4),
                              Text(fmt.format(p.price),
                                  style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Size ──────────────────────────────────────────────
                    if (sizesAsync != null)
                      sizesAsync.when(
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                        data: (sizes) => sizes.isEmpty
                            ? const SizedBox()
                            : _buildSizeSection(fmt, sizes),
                      ),

                    // ── Temperature ────────────────────────────────────────
                    if (tempsAsync != null)
                      tempsAsync.when(
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                        data: (temps) => temps.isEmpty
                            ? const SizedBox()
                            : _buildTempSection(fmt, temps),
                      ),

                    // ── Sugar Level ────────────────────────────────────────
                    if (sugarsAsync != null)
                      sugarsAsync.when(
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                        data: (sugars) => sugars.isEmpty
                            ? const SizedBox()
                            : _buildSugarSection(fmt, sugars),
                      ),

                    // ── Add-ons ────────────────────────────────────────────
                    if (addonsAsync != null)
                      addonsAsync.when(
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                        data: (addonsList) => addonsList.isEmpty
                            ? const SizedBox()
                            : _buildAddonsSection(fmt, addonsList),
                      ),

                    // ── Notes ──────────────────────────────────────────────
                    _sectionHeader('Special Notes'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Any special requests for the barista?',
                        fillColor: AppTheme.surfaceContainerHighest,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // ── Bottom Action Bar ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.onSurfaceVariant)),
                      Text(fmt.format(totalPrice),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                              fontSize: 18)),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: SizedBox(
                      height: 58,
                      child: ElevatedButton(
                        onPressed: () {
                          final addonLabels = addons
                              .where((a) => selectedAddonIds.contains(a.id))
                              .map((a) => a.label)
                              .toList();

                          Navigator.pop(
                            context,
                            CustomizationOptions(
                              size: selectedSize,
                              sizePriceModifier: selectedSizePrice,
                              temperature: selectedTemp,
                              tempPriceModifier: selectedTempPrice,
                              sugarLevel: selectedSugar,
                              sugarPriceModifier: selectedSugarPrice,
                              selectedAddons: addonLabels,
                              addonsTotal: _addonsTotal,
                              notes: _notesController.text,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_shopping_cart,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Add to Cart',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section builders ────────────────────────────────────────────────────────

  Widget _buildSizeSection(NumberFormat fmt, List<CustomizationOption> sizes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Size', trailing: 'Affects price'),
        const SizedBox(height: 12),
        Row(
          children: sizes.asMap().entries.map((entry) {
            final s = entry.value;
            final price = _getEffectivePrice(s);
            final isSelected = selectedSize == s.label;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: entry.key > 0 ? 10 : 0),
                child: GestureDetector(
                  onTap: () => setState(() {
                    selectedSize = s.label;
                    selectedSizePrice = price;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.transparent,
                          width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(s.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.onSurface,
                            )),
                        const SizedBox(height: 2),
                        Text(s.subtitle,
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.onSurfaceVariant)),
                        if (price > 0) ...[
                          const SizedBox(height: 2),
                          Text('+${fmt.format(price)}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildTempSection(NumberFormat fmt, List<CustomizationOption> temps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Temperature'),
        const SizedBox(height: 12),
        Row(
          children: temps.asMap().entries.map((entry) {
            final t = entry.value;
            final price = _getEffectivePrice(t);
            final isSelected = selectedTemp == t.label;
            final activeColor =
                t.label == 'Hot' ? AppTheme.error : AppTheme.primary;
            final icon =
                t.label == 'Hot' ? Icons.wb_sunny_outlined : Icons.ac_unit;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: entry.key > 0 ? 10 : 0),
                child: GestureDetector(
                  onTap: () => setState(() {
                    selectedTemp = t.label;
                    selectedTempPrice = price;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? activeColor.withValues(alpha: 0.1)
                          : AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: isSelected ? activeColor : Colors.transparent,
                          width: 2),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon,
                                size: 18,
                                color: isSelected
                                    ? activeColor
                                    : AppTheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(t.label,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? activeColor
                                        : AppTheme.onSurface)),
                          ],
                        ),
                        if (price > 0) ...[
                          const SizedBox(height: 2),
                          Text('+${fmt.format(price)}',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: activeColor,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildSugarSection(
      NumberFormat fmt, List<CustomizationOption> sugars) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Sugar Level'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: sugars.map((s) {
            final price = _getEffectivePrice(s);
            final isSelected = selectedSugar == s.label;
            return ChoiceChip(
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.label),
                  if (price > 0)
                    Text('+${fmt.format(price)}',
                        style: const TextStyle(
                            fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    selectedSugar = s.label;
                    selectedSugarPrice = price;
                  });
                }
              },
              selectedColor: AppTheme.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: AppTheme.surfaceContainerLow,
              side: BorderSide(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  width: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildAddonsSection(
      NumberFormat fmt, List<CustomizationOption> addonsList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Add-ons', trailing: 'Optional'),
        const SizedBox(height: 12),
        ...addonsList.asMap().entries.map((entry) {
          final addon = entry.value;
          final price = _getEffectivePrice(addon);
          final isSelected = selectedAddonIds.contains(addon.id);
          return Padding(
            padding: EdgeInsets.only(top: entry.key > 0 ? 10 : 0),
            child: GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  selectedAddonIds.remove(addon.id);
                } else {
                  selectedAddonIds.add(addon.id);
                }
                _recalcAddons(addonsList);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withValues(alpha: 0.08)
                      : AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.onSurfaceVariant),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(addon.label,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text('+${fmt.format(price)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isSelected ? AppTheme.primary : Colors.transparent,
                        border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.outlineVariant),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _sectionHeader(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        if (trailing != null)
          Text(trailing,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold)),
      ],
    );
  }
}
