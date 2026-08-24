import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/cart_model.dart';
import '../../../../core/network/api_endpoints.dart';

const _localCartKey = 'local_cart';

class CartRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  CartRepository(this._dio, this._storage);

  // ── LOCAL (guest) ──────────────────────────────────────────
  Future<List<CartLead>> fetchLocalCart() async {
    final raw = await _storage.read(key: _localCartKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => CartLead.fromJson(e)).toList();
  }

  Future<void> saveLocalCart(List<CartLead> items) async {
    await _storage.write(
      key: _localCartKey,
      value: jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clearLocalCart() async => _storage.delete(key: _localCartKey);

  // ── REMOTE (logged-in) ─────────────────────────────────────

  /// GET cart
  Future<List<CartLead>> fetchRemoteCart() async {
    try {
      final res = await _dio.get(ApiEndpoints.cart);

  
      final dynamic data = res.data['data'];
      if (data != null && data['leads'] != null) {
        final List leadsList = data['leads'];
        return leadsList.map((e) => CartLead.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE item
Future<String> deleteRemoteItem(String id, int quantity) async {
    final res = await _dio.delete(
      ApiEndpoints.deleteCartItem, 
      data: {
        'leadId': id,
        'quantity': quantity, // ✅ Send the quantity to the backend
      }
    );
    // Return the message from the backend, or a default string
    return res.data['message'] ?? "Cart updated successfully";
  }

  /// ADD to cart
  Future<String> addToCartRemote(String id, int quantity) async {
    final res = await _dio.post(
      ApiEndpoints.addToCart, 
      data: {
        'leadId': id,
        'quantity': quantity,
      }
    );
    return res.data['message'] ?? "Added to cart";
  }

  /// CHECKOUT
  Future<void> checkoutRemote(String id) async {
    await _dio.post(ApiEndpoints.checkoutCart, data: {'leadId': id});
  }

  /// PAY
  Future<void> proceedToPayRemote(List<String> ids) async {
    await _dio.post(ApiEndpoints.payCart, data: {'ids': ids});
  }

  // ── SYNC local → backend on login ─────────────────────────
  Future<void> syncLocalToRemote() async {
    final local = await fetchLocalCart();
    if (local.isEmpty) return;

    try {
      for (var item in local) {
        if (item.id.isNotEmpty) {
          await _dio.post(
            ApiEndpoints.addToCart,
            data: {
              'leadId': item.id, 
              'quantity': item.quantity ?? 1, 
            }, 
          );
        } else {
          debugPrint("Skipping sync for item with empty ID: ${item.title}");
        }
      }
      await clearLocalCart();
    } catch (e) {
      debugPrint("Sync failed during POST: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createRazorpayOrder(List<String> leadIds) async {
    final res = await _dio.post(
      ApiEndpoints.payCart,
      data: {'ids': leadIds},
    );
    final data = res.data['data'];
    if (data is! Map) {
      throw Exception(
        res.data['message']?.toString() ?? 'Failed to create payment order',
      );
    }
    return Map<String, dynamic>.from(data);
  }

  /// 2. Verify Payment on Backend
  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final res = await _dio.post(
      ApiEndpoints.verifyPayment, 
      data: {
        "razorpayOrderId": orderId,
        "razorpayPaymentId": paymentId,
        "razorpaySignature": signature,
      },
    );
    return res.data['success'] == true;
  }

  Future<Response<List<int>>> downloadLeadsFileWithResponse(
    String orderId,
  ) async {
    try {
      final Response<List<int>> res = await _dio.get<List<int>>(
        ApiEndpoints.downloadLead(orderId),
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) => status! < 500,
        ),
      );
      return res;
    } catch (e) {
      debugPrint("Repo Download Error: $e");
      rethrow;
    }
  }
}
