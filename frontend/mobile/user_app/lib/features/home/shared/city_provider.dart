import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/features/home/domain/city_model.dart';
import 'package:user_app/features/home/infra/city_controller.dart';

final cityRepositoryProvider = Provider<CityRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CityRepository(dio);
});

// ── Fetch cities from API ──────────────────────────────────────
final cityListProvider = FutureProvider<List<CityModel>>((ref) {
  return ref.watch(cityRepositoryProvider).getCities();
});

// ── Search query inside the picker sheet ──────────────────────
final citySearchQueryProvider = StateProvider<String>((_) => '');

// ── Filtered list ─────────────────────────────────────────────
final filteredCityListProvider = Provider<AsyncValue<List<CityModel>>>((ref) {
  final citiesAsync = ref.watch(cityListProvider);
  final query = ref.watch(citySearchQueryProvider).toLowerCase().trim();

  return citiesAsync.whenData((cities) {
    if (query.isEmpty) return cities;
    return cities.where((c) => c.name.toLowerCase().contains(query)).toList();
  });
});

// ── Currently selected city (null = "All Cities") ─────────────
final selectedCityProvider = StateProvider<CityModel?>((_) => null);
