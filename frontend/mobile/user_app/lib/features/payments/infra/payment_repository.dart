import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/network/api_endpoints.dart';
import 'package:user_app/core/network/dio_provider.dart'; 
import '../domain/payment_model.dart';

class HistoryRepository {
  final Dio _dio;
  HistoryRepository(this._dio);

  Future<List<HistoryModel>> fetchHistory(String type) async {
    // type will be 'ALL', 'PAYMENT', or 'LEAD'
    final res = await _dio.get(ApiEndpoints.getPayments,
      queryParameters: {
        'type': type, // Dio automatically formats this to ?type=ALL
      },);
    
    final data = res.data['data'] as List;
    return data.map((json) => HistoryModel.fromJson(json)).toList();
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(dioProvider));
});