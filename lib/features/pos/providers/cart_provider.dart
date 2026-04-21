import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulu_coffee_pos/shared/models/product_models.dart';

class CartState {
  final List<CartItem> items;

  CartState({this.items = const []});

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void _generateIdAndAdd(Product product, CustomizationOptions options, int quantity) {
    // Generate a unique ID based on product ID and options combination
    final comboId = '${product.id}_${options.hashCode}';
    
    final existingIndex = state.items.indexWhere((item) => item.id == comboId);
    
    if (existingIndex >= 0) {
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + quantity
      );
      state = state.copyWith(items: updatedItems);
    } else {
      final newItem = CartItem(
        id: comboId,
        product: product,
        options: options,
        quantity: quantity,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void addToCart(Product product, {CustomizationOptions options = const CustomizationOptions(), int quantity = 1}) {
    _generateIdAndAdd(product, options, quantity);
  }

  void updateQuantity(String cartItemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(cartItemId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.id == cartItemId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void removeItem(String cartItemId) {
    final updatedItems = state.items.where((item) => item.id != cartItemId).toList();
    state = state.copyWith(items: updatedItems);
  }

  void clearCart() {
    state = state.copyWith(items: []);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
