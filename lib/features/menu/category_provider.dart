import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulu_coffee_pos/core/database/category_repository.dart';
import 'package:hulu_coffee_pos/shared/models/category_model.dart';

final categoryNotifierProvider =
    AsyncNotifierProvider<CategoryNotifier, List<Category>>(
        CategoryNotifier.new);

class CategoryNotifier extends AsyncNotifier<List<Category>> {
  late CategoryRepository _repo;

  @override
  Future<List<Category>> build() async {
    _repo = ref.read(categoryRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> add(String displayName) async {
    final cat = _repo.buildNew(displayName);
    await _repo.insert(cat);
    ref.invalidateSelf();
  }

  Future<void> rename(Category cat, String newDisplayName) async {
    await _repo.update(cat.copyWith(displayName: newDisplayName));
    ref.invalidateSelf();
  }

  Future<void> delete(Category cat) async {
    if (cat.isBuiltIn) return; // protect built-ins
    await _repo.delete(cat.id);
    ref.invalidateSelf();
  }
}
