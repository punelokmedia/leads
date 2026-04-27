import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:user_app/features/home/domain/leads_model.dart';
import '../domain/cart_model.dart';
import 'cart_repository.dart';

class CartController extends StateNotifier<CartState> {
  final CartRepository _repo;
  final bool _isLoggedIn;
  late Razorpay _razorpay;

  CartController(this._repo, this._isLoggedIn) : super(const CartState()) {
    _init();
    _razorpay = Razorpay();
  }

  Future<void> _init() async {
    if (_isLoggedIn) {
      // 1. If user just logged in, move items from Secure Storage to API
      await _syncGuestCartToRemote();
    }
    await loadCart();
  }

  Future<void> loadCart() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = _isLoggedIn
          ? await _repo.fetchRemoteCart()
          : await _repo.fetchLocalCart();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> addLeadToCart(LeadModel lead) async {
    final newItem = CartLead(
      id: lead.id.toString(),
      title: lead.title,
      location: lead.city,
      name: lead.title,
      address: lead.address,
      time: lead.date,
      sharingCount: lead.sharingCount.toString(),
      imageUrl: lead.imageUrl,
      isSelected: true,
    );

    String? resultMessage;

    if (_isLoggedIn) {
      try {
        resultMessage = await _repo.addToCartRemote(
          newItem.id,
          newItem.quantity,
        );
      } catch (e) {
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map) {
            resultMessage = data['message']?.toString() ?? "Failed to add to cart";
          } else {
            resultMessage = "Failed to add to cart";
          }
        } else {
          resultMessage = "Failed to add to cart";
        }
        state = state.copyWith(error: resultMessage);
        return resultMessage;
      }
    } else {
      final currentItems = await _repo.fetchLocalCart();
      if (!currentItems.any((e) => e.id == newItem.id)) {
        final updated = [...currentItems, newItem];
        await _repo.saveLocalCart(updated);
        resultMessage = "Lead added to local cart!";
      } else {
        resultMessage = "Already in cart";
      }
    }

    await loadCart();
    return resultMessage;
  }

  int getQuantityForLead(String id) {
    final item = state.items.where((e) => e.id == id).firstOrNull;
    return item?.quantity ?? 0;
  }

  Future<String?> incrementLead(LeadModel lead) async {
    final existingItem = state.items
        .where((e) => e.id == lead.id.toString())
        .firstOrNull;

    final newQuantity = (existingItem?.quantity ?? 0) + 1;
    String? resultMessage;

    if (_isLoggedIn) {
      try {
        resultMessage = await _repo.addToCartRemote(lead.id.toString(), 1);
      } catch (e) {
        String errMsg = "Failed to update cart";
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map) {
            errMsg = data['message']?.toString() ?? errMsg;
          }
        }
        state = state.copyWith(error: errMsg);
        return errMsg;
      }
    } else {
      resultMessage = "Added to local cart";
    }
    if (existingItem != null) {
      final updatedItems = state.items
          .map(
            (e) => e.id == lead.id.toString()
                ? e.copyWith(quantity: newQuantity)
                : e,
          )
          .toList();
      state = state.copyWith(items: updatedItems);
      if (!_isLoggedIn) await _repo.saveLocalCart(updatedItems);
    } else {
      final newItem = CartLead(
        id: lead.id.toString(),
        title: lead.title,
        location: lead.city,
        name: lead.title,
        address: lead.address,
        time: lead.date,
        sharingCount: lead.sharingCount.toString(),
        imageUrl: lead.imageUrl,
        isSelected: true,
        quantity: newQuantity,
      );

      final updatedItems = [...state.items, newItem];
      state = state.copyWith(items: updatedItems);
      if (!_isLoggedIn) await _repo.saveLocalCart(updatedItems);
    }

    return resultMessage;
  }

  // ── DECREMENT / REMOVE FROM CART ──
  Future<String?> decrementLead(String id) async {
    final existingItem = state.items.where((e) => e.id == id).firstOrNull;
    if (existingItem == null) return null;

    final newQuantity = (existingItem.quantity) - 1;
    String? resultMessage;

    if (newQuantity <= 0) {
      await deleteItem(id);
      return "Item removed from cart";
    } else {
      if (_isLoggedIn) {
        try {
          // ✅ FIX: Call the decrease API instead of the add API!
          // Pass positive 1, so the backend knows to subtract 1 quantity.
          resultMessage = await _repo.deleteRemoteItem(id, 1);
        } catch (e) {
          String errMsg = "Failed to update cart";
          if (e is DioException && e.response?.data != null) {
            if (e.response?.data is Map) {
              errMsg = e.response?.data['message'] ?? errMsg;
            }
          }
          state = state.copyWith(error: errMsg);
          return errMsg;
        }
      } else {
        resultMessage = "Cart updated locally";
      }

      final updatedItems = state.items
          .map((e) => e.id == id ? e.copyWith(quantity: newQuantity) : e)
          .toList();

      state = state.copyWith(items: updatedItems);
      if (!_isLoggedIn) await _repo.saveLocalCart(updatedItems);

      return resultMessage;
    }
  }

  Future<void> _syncGuestCartToRemote() async {
    try {
      await _repo.syncLocalToRemote();
    } catch (e) {
      debugPrint("Sync error in Controller: $e");
    }
  }

  void toggleSelect(String id) {
    state = state.copyWith(
      items: state.items
          .map((e) => e.id == id ? e.copyWith(isSelected: !e.isSelected) : e)
          .toList(),
    );
    if (!_isLoggedIn) _repo.saveLocalCart(state.items);
  }

  Future<void> deleteItem(String id) async {
    if (_isLoggedIn) {
      await _repo.deleteRemoteItem(id, 1);
    }
    final updated = state.items.where((e) => e.id != id).toList();
    state = state.copyWith(items: updated);
    if (!_isLoggedIn) await _repo.saveLocalCart(updated);
  }

  Future<void> addToCart(String id) async {
    final existingItem = state.items.where((e) => e.id == id).firstOrNull;
    final quantity = existingItem?.quantity ?? 1;
    if (_isLoggedIn) {
      try {
        await _repo.addToCartRemote(id, quantity);
      } catch (e) {
        state = state.copyWith(error: "Failed to sync with remote cart");
        return; 
      }
    }
    if (existingItem != null) {
      final updatedItems = state.items
          .map((e) => e.id == id ? e.copyWith(isSelected: true) : e)
          .toList();

      state = state.copyWith(items: updatedItems);
      if (!_isLoggedIn) await _repo.saveLocalCart(updatedItems);
    }
  }

  Future<bool> proceedToPay() async {
    try {
      final selected = state.items.where((e) => e.isSelected).toList();
      if (selected.isEmpty) return false;
      if (_isLoggedIn) {
        await _repo.proceedToPayRemote(selected.map((e) => e.id).toList());
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> startPaymentProcess({
    required Function(Map<String, dynamic>) onOrderCreated,
    required Function(String) onError,
  }) async {
    final selectedIds = state.items
        .where((e) => e.isSelected)
        .map((e) => e.id)
        .toList();
    if (selectedIds.isEmpty) {
      onError("Please select items to buy");
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final orderData = await _repo.createRazorpayOrder(selectedIds);
      final dynamic rawAmount = orderData['amount'];
      final int finalAmount = (rawAmount as num).toInt() * 100;

      state = state.copyWith(
        isLoading: false,
        activeInternalOrderId: orderData['internalOrderId'],
        lastOrderDetails: {'amount': rawAmount.toString()},
      );

      final Map<String, dynamic> optimizedData = {
        ...orderData,
        'amount': finalAmount,
      };

      onOrderCreated(optimizedData);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      onError("Failed to initialize payment");
    }
  }

  Future<String?> verifyFinalPayment(PaymentSuccessResponse response) async {
    if (response.paymentId == null || response.orderId == null) return null;

    state = state.copyWith(isLoading: true);
    try {
      final success = await _repo.verifyPayment(
        orderId: response.orderId!,
        paymentId: response.paymentId!,
        signature: response.signature ?? '',
      );

      if (success) {
        final internalId = state.activeInternalOrderId;
        final savedAmount = state.lastOrderDetails?['amount'] ?? '0.00';

        await loadCart();

        state = state.copyWith(
          isLoading: false,
          activeInternalOrderId: null,
          lastOrderDetails: {
            'orderId': response.orderId,
            'paymentId': response.paymentId,
            'amount': savedAmount, 
            'date': DateTime.now().toIso8601String(),
          },
        );
        return internalId;
      }
      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return null;
    }
  }
// ✅ Changed to Future<String?> to return the file path to the UI
  Future<String?> downloadLeads(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repo.downloadLeadsFileWithResponse(orderId);

      // 1. Handle Backend Errors
      if (response.statusCode != 200) {
        String errorMessage = "Download failed";

        try {
          final String errorJsonString = utf8.decode(
            response.data as List<int>,
          );
          final Map<String, dynamic> errorData = jsonDecode(errorJsonString);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          debugPrint("Could not parse error JSON: $e");
        }

        state = state.copyWith(isLoading: false, error: errorMessage);
        return null; 
      }

      // 2. Handle Successful Download
      final List<int> bytes = response.data ?? [];
      if (bytes.isEmpty) throw Exception("File is empty");
      
      String extension = 'xlsx';
      final contentType = response.headers.value('content-type');
      if (contentType?.contains('pdf') ?? false) extension = 'pdf';

      // ✅ Use the custom public Download directory
      Directory dir = await getDownloadDirectory();
      
      final String filePath =
          "${dir.path}/Leads_${orderId}_${DateTime.now().millisecondsSinceEpoch}.$extension";
      
      final File file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      state = state.copyWith(isLoading: false);
      
      // ✅ Return the file path so the UI knows it succeeded
      return filePath; 

    } catch (e) {
      debugPrint("Download System Error: $e");
      state = state.copyWith(
        isLoading: false,
        error: "Something went wrong. Please try again.",
      );
      return null;
    }
  }

  // ✅ Force Android to use the public Downloads folder
  Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      // Ensure the directory exists before trying to save
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir; 
    } else {
      // iOS fallback
      return await getApplicationDocumentsDirectory();
    }
  }
}
