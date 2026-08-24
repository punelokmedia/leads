import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:user_app/core/errors/error_handler.dart';
import 'package:user_app/features/home/domain/leads_model.dart';
import '../domain/cart_model.dart';
import 'cart_repository.dart';

class CartController extends StateNotifier<CartState> {
  final CartRepository _repo;
  final bool _isLoggedIn;
  late Razorpay _razorpay;
  bool _isDisposed = false; // ✅ Add this

  CartController(this._repo, this._isLoggedIn) : super(const CartState()) {
    _init();
    _razorpay = Razorpay();
  }

  // ✅ Safe setState helper
  void _safeSetState(CartState Function(CartState) updater) {
    if (_isDisposed) return;
    state = updater(state);
  }

  @override
  void dispose() {
    _isDisposed = true; // ✅ Mark disposed
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _init() async {
    if (_isLoggedIn) await _syncGuestCartToRemote();
    await loadCart();
  }

  Future<void> loadCart() async {
    _safeSetState((s) => s.copyWith(isLoading: true));
    try {
      final items = _isLoggedIn
          ? await _repo.fetchRemoteCart()
          : await _repo.fetchLocalCart();
      if (_isDisposed) return; // ✅ Guard after await
      _safeSetState((s) => s.copyWith(items: items, isLoading: false));
    } catch (e) {
      _safeSetState((s) => s.copyWith(isLoading: false, error: e.toString()));
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
        if (_isDisposed) return null; // ✅
      } catch (e) {
        if (_isDisposed) return null; // ✅
        if (e is DioException) {
          final data = e.response?.data;
          resultMessage = (data is Map)
              ? data['message']?.toString() ?? "Failed to add to cart"
              : "Failed to add to cart";
        } else {
          resultMessage = "Failed to add to cart";
        }
        _safeSetState((s) => s.copyWith(error: resultMessage));
        return resultMessage;
      }
    } else {
      final currentItems = await _repo.fetchLocalCart();
      if (_isDisposed) return null; // ✅
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

  Future<String?> incrementLead(LeadModel lead) async {
    final existingItem = state.items
        .where((e) => e.id == lead.id.toString())
        .firstOrNull;
    final newQuantity = (existingItem?.quantity ?? 0) + 1;
    String? resultMessage;

    if (_isLoggedIn) {
      try {
        resultMessage = await _repo.addToCartRemote(lead.id.toString(), 1);
        if (_isDisposed) return null; // ✅
      } catch (e) {
        if (_isDisposed) return null; // ✅
        String errMsg = "Failed to update cart";
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map) errMsg = data['message']?.toString() ?? errMsg;
        }
        _safeSetState((s) => s.copyWith(error: errMsg));
        return errMsg;
      }
    } else {
      resultMessage = "Added to local cart";
    }

    if (_isDisposed) return null; // ✅

    if (existingItem != null) {
      final updatedItems = state.items
          .map(
            (e) => e.id == lead.id.toString()
                ? e.copyWith(quantity: newQuantity)
                : e,
          )
          .toList();
      _safeSetState((s) => s.copyWith(items: updatedItems));
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
      _safeSetState((s) => s.copyWith(items: updatedItems));
      if (!_isLoggedIn) await _repo.saveLocalCart(updatedItems);
    }
    return resultMessage;
  }

  Future<String?> decrementLead(String id) async {
    final existingItem = state.items.where((e) => e.id == id).firstOrNull;
    if (existingItem == null) return null;

    final newQuantity = existingItem.quantity - 1;

    if (newQuantity <= 0) {
      await deleteItem(id);
      return "Item removed from cart";
    }

    String? resultMessage;
    if (_isLoggedIn) {
      try {
        resultMessage = await _repo.deleteRemoteItem(id, 1);
        if (_isDisposed) return null; // ✅
      } catch (e) {
        if (_isDisposed) return null; // ✅
        String errMsg = "Failed to update cart";
        if (e is DioException && e.response?.data is Map) {
          errMsg = e.response?.data['message'] ?? errMsg;
        }
        _safeSetState((s) => s.copyWith(error: errMsg));
        return errMsg;
      }
    } else {
      resultMessage = "Cart updated locally";
    }

    final updatedItems = state.items
        .map((e) => e.id == id ? e.copyWith(quantity: newQuantity) : e)
        .toList();
    _safeSetState((s) => s.copyWith(items: updatedItems));
    if (!_isLoggedIn) await _repo.saveLocalCart(updatedItems);
    return resultMessage;
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

    _safeSetState((s) => s.copyWith(isLoading: true));
    try {
      final orderData = await _repo.createRazorpayOrder(selectedIds);
      if (_isDisposed) return; // ✅

      if (orderData['razorpayOrderId'] == null && orderData['orderId'] == null) {
        throw Exception('Payment order ID missing');
      }

      final dynamic rawAmount = orderData['amount'];
      final parsedAmount = rawAmount is num
          ? rawAmount.toInt()
          : int.tryParse(rawAmount?.toString() ?? '') ?? 0;
      // Backend cart order amount is in INR; Razorpay checkout needs paise.
      final int finalAmount = parsedAmount * 100;

      _safeSetState(
        (s) => s.copyWith(
          isLoading: false,
          activeInternalOrderId: orderData['internalOrderId'],
          lastOrderDetails: {'amount': rawAmount.toString()},
        ),
      );

      onOrderCreated({...orderData, 'amount': finalAmount});
    } catch (e) {
      final message = ErrorHandler.handle(e).message;
      _safeSetState((s) => s.copyWith(isLoading: false, error: message));
      onError(message);
    }
  }

  Future<String?> verifyFinalPayment(PaymentSuccessResponse response) async {
    if (response.paymentId == null || response.orderId == null) return null;

    _safeSetState((s) => s.copyWith(isLoading: true));
    try {
      final success = await _repo.verifyPayment(
        orderId: response.orderId!,
        paymentId: response.paymentId!,
        signature: response.signature ?? '',
      );
      if (_isDisposed) return null; // ✅

      if (success) {
        final internalId = state.activeInternalOrderId;
        final savedAmount = state.lastOrderDetails?['amount'] ?? '0.00';
        await loadCart();
        if (_isDisposed) return null; // ✅

        _safeSetState(
          (s) => s.copyWith(
            isLoading: false,
            activeInternalOrderId: null,
            lastOrderDetails: {
              'orderId': response.orderId,
              'paymentId': response.paymentId,
              'amount': savedAmount,
              'date': DateTime.now().toIso8601String(),
            },
          ),
        );
        return internalId;
      }
      _safeSetState((s) => s.copyWith(isLoading: false));
      return null;
    } catch (e) {
      _safeSetState((s) => s.copyWith(isLoading: false));
      return null;
    }
  }

  Future<String?> downloadLeads(String orderId) async {
    _safeSetState((s) => s.copyWith(isLoading: true, error: null));
    try {
      final response = await _repo.downloadLeadsFileWithResponse(orderId);
      if (_isDisposed) return null; // ✅

      if (response.statusCode != 200) {
        String errorMessage = "Download failed";
        try {
          final errorData = jsonDecode(utf8.decode(response.data as List<int>));
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        _safeSetState((s) => s.copyWith(isLoading: false, error: errorMessage));
        return null;
      }

      final List<int> bytes = response.data ?? [];
      if (bytes.isEmpty) throw Exception("File is empty");

      String extension = 'xlsx';
      final contentType = response.headers.value('content-type');
      if (contentType?.contains('pdf') ?? false) extension = 'pdf';

      final dir = await getDownloadDirectory();
      if (_isDisposed) return null; // ✅

      final filePath =
          "${dir.path}/Leads_${orderId}_${DateTime.now().millisecondsSinceEpoch}.$extension";
      await File(filePath).writeAsBytes(bytes, flush: true);

      _safeSetState((s) => s.copyWith(isLoading: false));
      return filePath;
    } catch (e) {
      debugPrint("Download System Error: $e");
      _safeSetState(
        (s) => s.copyWith(
          isLoading: false,
          error: "Something went wrong. Please try again.",
        ),
      );
      return null;
    }
  }

  // ── Unchanged methods ──
  int getQuantityForLead(String id) {
    return state.items.where((e) => e.id == id).firstOrNull?.quantity ?? 0;
  }

  void toggleSelect(String id) {
    _safeSetState(
      (s) => s.copyWith(
        items: s.items
            .map((e) => e.id == id ? e.copyWith(isSelected: !e.isSelected) : e)
            .toList(),
      ),
    );
    if (!_isLoggedIn) _repo.saveLocalCart(state.items);
  }

  Future<void> deleteItem(String id) async {
    if (_isLoggedIn) await _repo.deleteRemoteItem(id, 1);
    if (_isDisposed) return; // ✅
    final updated = state.items.where((e) => e.id != id).toList();
    _safeSetState((s) => s.copyWith(items: updated));
    if (!_isLoggedIn) await _repo.saveLocalCart(updated);
  }

  Future<void> addToCart(String id) async {
    final existingItem = state.items.where((e) => e.id == id).firstOrNull;
    final quantity = existingItem?.quantity ?? 1;
    if (_isLoggedIn) {
      try {
        await _repo.addToCartRemote(id, quantity);
        if (_isDisposed) return; // ✅
      } catch (e) {
        _safeSetState(
          (s) => s.copyWith(error: "Failed to sync with remote cart"),
        );
        return;
      }
    }
    if (existingItem != null) {
      final updatedItems = state.items
          .map((e) => e.id == id ? e.copyWith(isSelected: true) : e)
          .toList();
      _safeSetState((s) => s.copyWith(items: updatedItems));
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

  Future<void> _syncGuestCartToRemote() async {
    try {
      await _repo.syncLocalToRemote();
    } catch (e) {
      debugPrint("Sync error in Controller: $e");
    }
  }

  Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    }
    return await getApplicationDocumentsDirectory();
  }
}
