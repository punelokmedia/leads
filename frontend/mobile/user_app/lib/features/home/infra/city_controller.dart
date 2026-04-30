// lib/features/home/data/city_repository.dart

import 'package:dio/dio.dart';
import 'package:user_app/core/network/api_endpoints.dart';
import 'package:user_app/features/home/domain/city_model.dart';

class CityRepository {
  final Dio _dio;

  /// Pass the same [Dio] instance that already has [AuthInterceptor] attached.
  CityRepository(this._dio);

  /// GET api/v1/cities/get-all-cities
  Future<List<CityModel>> getCities() async {
    try {
      final response = await _dio.get(ApiEndpoints.getAllCities);

      // Your API envelope: { success: true, message: '...', data: [...] }
      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true) {
        final data = body['data'] as List<dynamic>;
        return data
            .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception(body['message'] ?? 'Failed to fetch cities');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception(msg);
    }
  }
}
