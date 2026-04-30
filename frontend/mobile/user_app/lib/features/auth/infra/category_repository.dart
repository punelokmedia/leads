// features/categories/infra/category_providers.dart

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/network/api_endpoints.dart';
import 'package:user_app/core/network/dio_provider.dart'; 

// ── 1. Model ──
class CategoryModel {
  final String id;
  final String name;
  final String icon; 

  CategoryModel({
    required this.id, 
    required this.name, 
    required this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '', 
    );
  }
}

// ── 2. Repository ──
class CategoryRepository {
  final Dio _dio;
  CategoryRepository(this._dio);

  Future<List<CategoryModel>> getAllCategories() async {
    final res = await _dio.get(ApiEndpoints.getAllCategories);
    final body = res.data as Map<String, dynamic>;
    final dataList = body['data'] as List<dynamic>;
    
    return dataList.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

// ── 3. Providers ──
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final dio = ref.watch(dioProvider); 
  return CategoryRepository(dio);
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getAllCategories();
});