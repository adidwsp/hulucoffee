import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulu_coffee_pos/core/database/customization_option_repository.dart';
import 'package:hulu_coffee_pos/shared/models/customization_option_model.dart';

final customizationOptionProvider =
    AsyncNotifierProvider<CustomizationOptionNotifier, List<CustomizationOption>>(
        CustomizationOptionNotifier.new);

class CustomizationOptionNotifier
    extends AsyncNotifier<List<CustomizationOption>> {
  late CustomizationOptionRepository _repo;

  @override
  Future<List<CustomizationOption>> build() async {
    _repo = ref.read(customizationOptionRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> add({
    required String type,
    required String label,
    String subtitle = '',
    double priceModifier = 0,
  }) async {
    // Get current max sort order for this type
    final current = await _repo.getByType(type);
    final maxSort = current.isEmpty
        ? 0
        : current.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

    final option = _repo.buildNew(
      type: type,
      label: label,
      subtitle: subtitle,
      priceModifier: priceModifier,
      sortOrder: maxSort,
    );
    await _repo.insert(option);
    ref.invalidateSelf();
  }

  Future<void> updateOption(CustomizationOption option) async {
    await _repo.update(option);
    ref.invalidateSelf();
  }

  Future<void> toggleActive(CustomizationOption option) async {
    await _repo.update(option.copyWith(isActive: !option.isActive));
    ref.invalidateSelf();
  }

  Future<void> deleteOption(String id) async {
    await _repo.delete(id);
    ref.invalidateSelf();
  }
}

/// Convenience providers for active options by type (used in POS)
final activeSizesProvider = FutureProvider<List<CustomizationOption>>((ref) {
  final repo = ref.watch(customizationOptionRepositoryProvider);
  return repo.getActiveByType(OptionType.size);
});

final activeTemperaturesProvider =
    FutureProvider<List<CustomizationOption>>((ref) {
  final repo = ref.watch(customizationOptionRepositoryProvider);
  return repo.getActiveByType(OptionType.temperature);
});

final activeSugarLevelsProvider =
    FutureProvider<List<CustomizationOption>>((ref) {
  final repo = ref.watch(customizationOptionRepositoryProvider);
  return repo.getActiveByType(OptionType.sugarLevel);
});

final activeAddonsProvider = FutureProvider<List<CustomizationOption>>((ref) {
  final repo = ref.watch(customizationOptionRepositoryProvider);
  return repo.getActiveByType(OptionType.addon);
});
