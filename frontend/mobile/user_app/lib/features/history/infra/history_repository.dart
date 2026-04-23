import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:user_app/core/network/api_endpoints.dart';

import '../domain/history_model.dart';

abstract class IHistoryRepository {
  Future<List<HistoryModel>> fetchHistory();
}

class HistoryRepository implements IHistoryRepository {
  final Dio _dio;
  HistoryRepository(this._dio);

  @override
  Future<List<HistoryModel>> fetchHistory() async {
    try {
      final res = await _dio.get(ApiEndpoints.history);

      if (res.statusCode == 200 && res.data['success'] == true) {
        final List data = res.data['data'] ?? [];
        List<HistoryModel> leads = [];

        for (var order in data) {
          try {
            if (order is! Map) continue;

            // ✅ FIX: The API returns 'items', not 'leads'
            if (order.containsKey('items') && order['items'] != null) {
              for (var item in order['items']) {
                if (item is Map) {
                  // Combine parent order data with the child item data
                  final combinedJson = Map<String, dynamic>.from(item);
                  combinedJson['orderId'] = order['orderId'];
                  combinedJson['paidAt'] = order['paidAt'];
                  combinedJson['status'] = order['status'];
                  combinedJson['isDownloaded'] = order['isDownloaded'];

                  leads.add(HistoryModel.fromJson(combinedJson));
                }
              }
            }
          } catch (e) {
            debugPrint("Error parsing individual history order: $e");
          }
        }
        return leads;
      }
      return [];
    } catch (e) {
      debugPrint("History Repository Error: $e");
      rethrow;
    }
  }
}
