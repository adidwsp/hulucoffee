import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hulu_coffee_pos/core/config/theme.dart';
import 'package:hulu_coffee_pos/shared/models/product_models.dart';

class ProductCustomizationSheet extends StatefulWidget {
  final Product product;
  const ProductCustomizationSheet({
    super.key,
    required this.product,
  });

  @override
  State<ProductCustomizationSheet> createState() => _ProductCustomizationSheetState();
}

class _ProductCustomizationSheetState extends State<ProductCustomizationSheet> {
  String selectedSize = 'Medium';
  String selectedTemp = 'Iced';
  String selectedSugar = 'Normal';
  int extraShots = 0;
  bool isOatMilk = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final totalPrice = widget.product.price + (extraShots * 15000) + (isOatMilk ? 10000 : 0);

    return Container(
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
          // Drag Handle
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
                  // Product Info Header
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.coffee, size: 40, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              widget.product.description,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatCurrency.format(widget.product.price),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Size Selection
                  _buildSectionHeader('Size', trailing: formatCurrency.format(widget.product.price)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildSizeOption('Small', '12 oz', selectedSize == 'Small', () => setState(() => selectedSize = 'Small'))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSizeOption('Medium', '16 oz', selectedSize == 'Medium', () => setState(() => selectedSize = 'Medium'))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSizeOption('Large', '20 oz', selectedSize == 'Large', () => setState(() => selectedSize = 'Large'))),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Temperature Selection
                  _buildSectionHeader('Temperature', trailing: 'Required'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTempOption('Hot', Icons.wb_sunny_outlined, selectedTemp == 'Hot', () => setState(() => selectedTemp = 'Hot'))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTempOption('Iced', Icons.ac_unit, selectedTemp == 'Iced', () => setState(() => selectedTemp = 'Iced'))),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Sugar Selection
                  _buildSectionHeader('Sugar Level'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: ['No Sugar', '25%', '50%', 'Normal'].map((sugar) {
                      final isSelected = selectedSugar == sugar;
                      return ChoiceChip(
                        label: Text(sugar),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => selectedSugar = sugar);
                        },
                        selectedColor: AppTheme.secondaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.onSecondaryContainer : AppTheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        backgroundColor: AppTheme.surfaceContainerLow,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Add-ons
                  _buildSectionHeader('Add-ons', trailing: 'Optional'),
                  const SizedBox(height: 12),
                  _buildAddonItem(
                    label: 'Extra Espresso Shot',
                    price: '+Rp 15.000',
                    icon: Icons.coffee_maker,
                    isSelected: extraShots > 0,
                    onTap: () => setState(() => extraShots = extraShots > 0 ? 0 : 1),
                  ),
                  const SizedBox(height: 12),
                  _buildAddonItem(
                    label: 'Oat Milk',
                    price: '+Rp 10.000',
                    icon: Icons.water_drop_outlined,
                    isSelected: isOatMilk,
                    onTap: () => setState(() => isOatMilk = !isOatMilk),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Special Notes
                  _buildSectionHeader('Special Notes'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Any special requests for the barista?',
                      fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          ),
          
          // Floating Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Estimate',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      formatCurrency.format(totalPrice),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          CustomizationOptions(
                            size: selectedSize,
                            temperature: selectedTemp,
                            sugarLevel: selectedSugar,
                            extraShots: extraShots,
                            notes: _notesController.text,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_shopping_cart, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
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
    );
  }

  Widget _buildSectionHeader(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildSizeOption(String label, String sub, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryFixedDim : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primary.withOpacity(0.3) : Colors.transparent),
        ),
        child: Column(
          children: [
            Icon(
              Icons.local_cafe,
              size: label == 'Large' ? 32 : (label == 'Medium' ? 28 : 24),
              color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primary : AppTheme.onSurface,
              ),
            ),
            Text(
              sub,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppTheme.primary.withOpacity(0.7) : AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTempOption(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    final activeColor = label == 'Hot' ? AppTheme.error : AppTheme.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? activeColor.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isSelected ? activeColor : AppTheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddonItem({
    required String label,
    required String price,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryFixedDim.withOpacity(0.5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.outlineVariant.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.primaryContainer),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(price, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primary : Colors.transparent,
                border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.outlineVariant),
              ),
              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }
}
