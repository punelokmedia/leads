import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:user_app/features/home/domain/lead_category.dart';
import 'package:user_app/core/network/api_endpoints.dart';
import 'package:user_app/core/network/dio_provider.dart';

final categorySearchProvider = StateProvider<String>((ref) => "");

final categoryListProvider = FutureProvider<List<LeadCategory>>((ref) async {
  final searchQuery = ref.watch(categorySearchProvider).toLowerCase();
  final dio = ref.watch(dioProvider);

  try {
    final response = await dio.get(ApiEndpoints.getAllCategories);
    if (response.statusCode == 200) {
      final List data = response.data['data'] ?? [];
      final allCategories = data.map((json) {
        return LeadCategory(
          id: json['_id'] ?? '',
          title: json['name'] ?? '',
          iconPath: json['icon'] ?? 'loc_pin',
          iconColor: Colors.blue, // Default color for backend categories
          isPopular: false,
        );
      }).toList();

      if (searchQuery.isEmpty) return allCategories;
      return allCategories.where((c) => c.title.toLowerCase().contains(searchQuery)).toList();
    }
  } catch (e) {
    debugPrint('Error fetching categories: $e');
  }

  return [];
});