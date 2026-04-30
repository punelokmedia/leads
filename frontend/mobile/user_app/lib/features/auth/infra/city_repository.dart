// features/cities/infra/city_repository.dart

import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:user_app/core/network/api_endpoints.dart';
import 'package:user_app/core/network/dio_provider.dart'; // Make sure this provides your Dio instance
import '../domain/city_model.dart';

// ── 1. Repository ──────────────────────────────────────────────────────────
class CityRepository {
  final Dio _dio;

  CityRepository(this._dio);

  Future<List<City>> getAllCities() async {
    final res = await _dio.get(ApiEndpoints.getAllCities);

    final body = res.data as Map<String, dynamic>;
    final dataList = body['data'] as List<dynamic>;

    // Map the raw JSON list into a strongly-typed List<City>
    return dataList
        .map((e) => City.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addCity({required String name}) async {
    await _dio.post(ApiEndpoints.addCity, data: {'name': name});
  }
}

// ── 2. Providers ───────────────────────────────────────────────────────────

// ✅ FIX: Added the missing Repository Provider!
final cityRepositoryProvider = Provider<CityRepository>((ref) {
  // Watch your global dioProvider here
  final dio = ref.watch(dioProvider); 
  return CityRepository(dio);
});

// ── 3. Controller for Adding Cities ──
class CityController extends StateNotifier<AsyncValue<void>> {
  final CityRepository _repo;

  CityController(this._repo) : super(const AsyncValue.data(null));

  Future<void> addCity({
    required String name,
    required VoidCallback onSuccess,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addCity(name: name);
      state = const AsyncValue.data(null);
      onSuccess();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final cityControllerProvider = StateNotifierProvider<CityController, AsyncValue<void>>((ref) {
  final repo = ref.watch(cityRepositoryProvider);
  return CityController(repo);
});

// ── 4. FutureProvider for Fetching Cities ──
// This automatically handles Loading, Success, and Error states!
final citiesProvider = FutureProvider<List<City>>((ref) async {
  final repo = ref.watch(cityRepositoryProvider);
  return repo.getAllCities();
});