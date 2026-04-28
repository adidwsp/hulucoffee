import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulu_coffee_pos/shared/models/product_models.dart';
import 'package:hulu_coffee_pos/core/database/product_repository.dart';

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProducts();
});

class ProductNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductRepository repository;

  ProductNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    try {
      final products = await repository.getProducts();
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addProduct(Product product) async {
    await repository.insertProduct(product);
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await repository.updateProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await repository.deleteProduct(id);
    await loadProducts();
  }

  Future<void> toggleAvailability(Product product) async {
    final updated = Product(
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      imageUrl: product.imageUrl,
      category: product.category,
      isAvailable: !product.isAvailable,
    );
    await repository.updateProduct(updated);
    await loadProducts();
  }
}

final productNotifierProvider =
    StateNotifierProvider<ProductNotifier, AsyncValue<List<Product>>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductNotifier(repository);
});
