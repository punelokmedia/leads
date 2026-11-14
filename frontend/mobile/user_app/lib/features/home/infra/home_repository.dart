import 'package:dio/dio.dart';
import 'package:user_app/core/network/api_endpoints.dart';
import 'package:user_app/features/home/domain/leads_model.dart';

abstract class IHomeRepository {
  Future<List<LeadModel>> fetchLeads({String? city, String? categoryId});
  Future<List<LeadModel>> searchLeads(String query);
}

class HomeRepository implements IHomeRepository {
  final Dio _dio;

  HomeRepository(this._dio);

  Future<List<LeadModel>> _fetch(Map<String, dynamic> filters) async {
    final leads = <LeadModel>[];
    var page = 1, pages = 1;
    do {
      final response = await _dio.get(
        ApiEndpoints.getAllLeads,
        queryParameters: {...filters, 'page': page, 'limit': 50},
      );
      if (response.data['success'] != true) {
        throw Exception(response.data['message']);
      }
      leads.addAll(
        (response.data['data'] as List).map(
          (row) => LeadModel.fromJson(Map<String, dynamic>.from(row)),
        ),
      );
      final pagination = response.data['pagination'];
      pages =
          (pagination?['totalPages'] as num?)?.toInt() ??
          ((pagination?['total'] as num? ?? 0) /
                  (pagination?['limit'] as num? ?? 50))
              .ceil();
      page++;
    } while (page <= pages);
    return leads;
  }

  @override
  Future<List<LeadModel>> fetchLeads({String? city, String? categoryId}) async {
    try {
      return await _fetch({
        if (city != null && city.isNotEmpty) 'city': city.toLowerCase(),
        if (categoryId != null && categoryId.isNotEmpty) 'category': categoryId,
      });
    } catch (e) {
      throw Exception('Failed to fetch leads: $e');
    }
  }

  @override
  Future<List<LeadModel>> searchLeads(String query) async {
    try {
      return await _fetch({'search': query});
    } catch (e) {
      throw Exception('Failed to search leads: $e');
    }
  }
}
