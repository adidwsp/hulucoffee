import 'package:equatable/equatable.dart';

// Keep this enum only for POS filter UI — not stored in DB anymore
enum ProductCategory { all, coffee, nonCoffee, tea, snacks }

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isAvailable;
  final String category; // NOW a plain String (category name key)

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isAvailable = true,
    required this.category,
  });

  @override
  List<Object?> get props =>
      [id, name, description, price, imageUrl, isAvailable, category];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'isAvailable': isAvailable ? 1 : 0,
        'category': category,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String,
        price: (map['price'] as num).toDouble(),
        imageUrl: map['imageUrl'] as String,
        isAvailable: (map['isAvailable'] as int?) == 1,
        category: map['category'] as String? ?? 'coffee',
      );

  Product copyWith({
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? isAvailable,
    String? category,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        imageUrl: imageUrl ?? this.imageUrl,
        isAvailable: isAvailable ?? this.isAvailable,
        category: category ?? this.category,
      );
}

class CustomizationOptions extends Equatable {
  final String? size;
  final String? temperature;
  final String? sugarLevel;
  final int extraShots;
  final String? notes;

  const CustomizationOptions({
    this.size = 'Regular',
    this.temperature = 'Iced',
    this.sugarLevel = 'Normal',
    this.extraShots = 0,
    this.notes,
  });

  @override
  List<Object?> get props =>
      [size, temperature, sugarLevel, extraShots, notes];

  CustomizationOptions copyWith({
    String? size,
    String? temperature,
    String? sugarLevel,
    int? extraShots,
    String? notes,
  }) =>
      CustomizationOptions(
        size: size ?? this.size,
        temperature: temperature ?? this.temperature,
        sugarLevel: sugarLevel ?? this.sugarLevel,
        extraShots: extraShots ?? this.extraShots,
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

  double get totalPrice => product.price * quantity;

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
