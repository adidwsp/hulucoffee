import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:hulu_coffee_pos/shared/models/customization_option_model.dart';

// Keep this enum only for POS filter UI — not stored in DB anymore
enum ProductCategory { all, coffee, nonCoffee, tea, snacks }

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isAvailable;
  final String category;

  /// Which option types are enabled for this product.
  /// Stored as JSON in DB, e.g. '["size","temperature","sugar_level","addon"]'
  /// Empty list = no customization (e.g. plain water, snacks)
  final List<String> enabledOptions;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isAvailable = true,
    required this.category,
    this.enabledOptions = const [
      OptionType.size,
      OptionType.temperature,
      OptionType.sugarLevel,
      OptionType.addon,
    ],
  });

  bool get hasCustomization => enabledOptions.isNotEmpty;
  bool get hasSize => enabledOptions.contains(OptionType.size);
  bool get hasTemperature => enabledOptions.contains(OptionType.temperature);
  bool get hasSugarLevel => enabledOptions.contains(OptionType.sugarLevel);
  bool get hasAddon => enabledOptions.contains(OptionType.addon);

  @override
  List<Object?> get props =>
      [id, name, description, price, imageUrl, isAvailable, category, enabledOptions];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'isAvailable': isAvailable ? 1 : 0,
        'category': category,
        'enabledOptions': jsonEncode(enabledOptions),
      };

  factory Product.fromMap(Map<String, dynamic> map) {
    List<String> parsedOptions;
    final raw = map['enabledOptions'];
    if (raw == null || (raw is String && raw.isEmpty)) {
      // Default for existing products: all options enabled
      parsedOptions = [
        OptionType.size,
        OptionType.temperature,
        OptionType.sugarLevel,
        OptionType.addon,
      ];
    } else {
      try {
        parsedOptions = List<String>.from(jsonDecode(raw as String));
      } catch (_) {
        parsedOptions = [];
      }
    }
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String,
      isAvailable: (map['isAvailable'] as int?) == 1,
      category: map['category'] as String? ?? 'coffee',
      enabledOptions: parsedOptions,
    );
  }

  Product copyWith({
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? isAvailable,
    String? category,
    List<String>? enabledOptions,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        imageUrl: imageUrl ?? this.imageUrl,
        isAvailable: isAvailable ?? this.isAvailable,
        category: category ?? this.category,
        enabledOptions: enabledOptions ?? this.enabledOptions,
      );
}

class CustomizationOptions extends Equatable {
  final String? size;
  final double sizePriceModifier;
  final String? temperature;
  final double tempPriceModifier;
  final String? sugarLevel;
  final double sugarPriceModifier;
  final List<String> selectedAddons;
  final double addonsTotal;
  final String? notes;

  const CustomizationOptions({
    this.size,
    this.sizePriceModifier = 0,
    this.temperature,
    this.tempPriceModifier = 0,
    this.sugarLevel,
    this.sugarPriceModifier = 0,
    this.selectedAddons = const [],
    this.addonsTotal = 0,
    this.notes,
  });

  double get totalModifier =>
      sizePriceModifier + tempPriceModifier + sugarPriceModifier + addonsTotal;

  @override
  List<Object?> get props => [
        size,
        sizePriceModifier,
        temperature,
        tempPriceModifier,
        sugarLevel,
        sugarPriceModifier,
        selectedAddons,
        addonsTotal,
        notes
      ];

  CustomizationOptions copyWith({
    String? size,
    double? sizePriceModifier,
    String? temperature,
    double? tempPriceModifier,
    String? sugarLevel,
    double? sugarPriceModifier,
    List<String>? selectedAddons,
    double? addonsTotal,
    String? notes,
  }) =>
      CustomizationOptions(
        size: size ?? this.size,
        sizePriceModifier: sizePriceModifier ?? this.sizePriceModifier,
        temperature: temperature ?? this.temperature,
        tempPriceModifier: tempPriceModifier ?? this.tempPriceModifier,
        sugarLevel: sugarLevel ?? this.sugarLevel,
        sugarPriceModifier: sugarPriceModifier ?? this.sugarPriceModifier,
        selectedAddons: selectedAddons ?? this.selectedAddons,
        addonsTotal: addonsTotal ?? this.addonsTotal,
        notes: notes ?? this.notes,
      );
}

class CartItem extends Equatable {
  final String id;
  final Product product;
  final int quantity;
  final CustomizationOptions options;

  const CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
    this.options = const CustomizationOptions(),
  });

  double get totalPrice => (product.price + options.totalModifier) * quantity;

  @override
  List<Object?> get props => [id, product, quantity, options];

  CartItem copyWith({int? quantity, CustomizationOptions? options}) =>
      CartItem(
        id: id,
        product: product,
        quantity: quantity ?? this.quantity,
        options: options ?? this.options,
      );
}
