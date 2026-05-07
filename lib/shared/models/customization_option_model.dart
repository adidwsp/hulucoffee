import 'package:equatable/equatable.dart';

/// Types of customization options
class OptionType {
  static const String size = 'size';
  static const String temperature = 'temperature';
  static const String sugarLevel = 'sugar_level';
  static const String addon = 'addon';

  static const List<String> all = [size, temperature, sugarLevel, addon];

  static String displayName(String type) {
    switch (type) {
      case size:
        return 'Size';
      case temperature:
        return 'Temperature';
      case sugarLevel:
        return 'Sugar Level';
      case addon:
        return 'Add-ons';
      default:
        return type;
    }
  }

  static IconLabel icon(String type) {
    switch (type) {
      case size:
        return const IconLabel(0xe560, 'straighten'); // Icons.straighten
      case temperature:
        return const IconLabel(0xe894, 'thermostat'); // Icons.thermostat
      case sugarLevel:
        return const IconLabel(0xef94, 'water_drop'); // Icons.water_drop
      case addon:
        return const IconLabel(0xe044, 'add_circle'); // Icons.add_circle
      default:
        return const IconLabel(0xe896, 'label');
    }
  }
}

class IconLabel {
  final int codePoint;
  final String name;
  const IconLabel(this.codePoint, this.name);
}

class CustomizationOption extends Equatable {
  final String id;
  final String type; // 'size', 'temperature', 'sugar_level', 'addon'
  final String label; // Display name e.g. "Medium", "Iced"
  final String subtitle; // Extra info e.g. "16 oz", ""
  final double priceModifier; // Price change e.g. 15000, 0
  final int sortOrder; // Display ordering
  final bool isActive; // Whether shown in POS

  const CustomizationOption({
    required this.id,
    required this.type,
    required this.label,
    this.subtitle = '',
    this.priceModifier = 0,
    this.sortOrder = 0,
    this.isActive = true,
  });

  @override
  List<Object?> get props =>
      [id, type, label, subtitle, priceModifier, sortOrder, isActive];

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'label': label,
        'subtitle': subtitle,
        'priceModifier': priceModifier,
        'sortOrder': sortOrder,
        'isActive': isActive ? 1 : 0,
      };

  factory CustomizationOption.fromMap(Map<String, dynamic> map) =>
      CustomizationOption(
        id: map['id'] as String,
        type: map['type'] as String,
        label: map['label'] as String,
        subtitle: map['subtitle'] as String? ?? '',
        priceModifier: (map['priceModifier'] as num?)?.toDouble() ?? 0,
        sortOrder: map['sortOrder'] as int? ?? 0,
        isActive: (map['isActive'] as int?) == 1,
      );

  CustomizationOption copyWith({
    String? label,
    String? subtitle,
    double? priceModifier,
    int? sortOrder,
    bool? isActive,
  }) =>
      CustomizationOption(
        id: id,
        type: type,
        label: label ?? this.label,
        subtitle: subtitle ?? this.subtitle,
        priceModifier: priceModifier ?? this.priceModifier,
        sortOrder: sortOrder ?? this.sortOrder,
        isActive: isActive ?? this.isActive,
      );
}
