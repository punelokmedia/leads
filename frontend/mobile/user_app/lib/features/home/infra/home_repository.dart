import 'package:dio/dio.dart';
import 'package:user_app/core/network/api_endpoints.dart';
import 'package:user_app/features/home/domain/leads_model.dart';

abstract class IHomeRepository {
  Future<List<LeadModel>> fetchLeads({String? city});
  Future<List<LeadModel>> searchLeads(String query);
}

class HomeRepository implements IHomeRepository {
  final Dio _dio;

  HomeRepository(this._dio);

  @override
  Future<List<LeadModel>> fetchLeads({String? city}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getAllLeads,
        queryParameters: {
          if (city != null && city.isNotEmpty) 'city': city.toLowerCase(),
        },
      );

      if (response.data['success'] == true) {
        final List list = response.data['data'];
        return list.map((json) => LeadModel.fromJson(json)).toList();
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Failed to fetch leads: $e');
    }
  }

  @override
  Future<List<LeadModel>> searchLeads(String query) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getAllLeads,
        queryParameters: {'search': query},
      );

      if (response.data['success'] == true) {
        final List list = response.data['data'];
        return list.map((json) => LeadModel.fromJson(json)).toList();
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Failed to search leads: $e');
    }
  }
}