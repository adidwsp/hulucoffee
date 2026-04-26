import 'package:equatable/equatable.dart';

enum ProductCategory { all, coffee, nonCoffee, tea, snacks }

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isAvailable;
  final ProductCategory category;

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
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        imageUrl,
        isAvailable,
        category,
      ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable ? 1 : 0,
      'category': category.name,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'],
      isAvailable: map['isAvailable'] == 1,
      category: ProductCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ProductCategory.coffee,
      ),
    );
  }
}

class CustomizationOptions extends Equatable {
  final String? size; // Regular, Large
  final String? temperature; // Hot, Iced
  final String? sugarLevel; // Normal, Less, No Sugar
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
  List<Object?> get props => [
        size,
        temperature,
        sugarLevel,
        extraShots,
        notes,
      ];

  CustomizationOptions copyWith({
    String? size,
    String? temperature,
    String? sugarLevel,
    int? extraShots,
    String? notes,
  }) {
    return CustomizationOptions(
      size: size ?? this.size,
      temperature: temperature ?? this.temperature,
      sugarLevel: sugarLevel ?? this.sugarLevel,
      extraShots: extraShots ?? this.extraShots,
      notes: notes ?? this.notes,
    );
  }
}

class CartItem extends Equatable {
  final String id; // Unique id for the cart item
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

  CartItem copyWith({
    int? quantity,
    CustomizationOptions? options,
  }) {
    return CartItem(
      id: id,
      product: product,
      quantity: quantity ?? this.quantity,
      options: options ?? this.options,
    );
  }
}
