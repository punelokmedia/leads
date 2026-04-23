// address/infra/address_controller.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import '../domain/address_model.dart';
import 'address_repository.dart';

class AddressController extends StateNotifier<AddressState> {
  final AddressRepository _repo;

  AddressController(this._repo)
    : super(AddressState(data: AddressModel.empty()));

  void updateField(AddressModel updated) =>
      state = state.copyWith(data: updated);

  void setType(AddressType type) =>
      state = state.copyWith(data: state.data.copyWith(type: type));

  Future<void> save({required VoidCallback onSuccess}) async {
    if (state.data.flatStreet.isEmpty ||
        state.data.city.isEmpty ||
        state.data.state.isEmpty ||
        state.data.zipcode.isEmpty) {
      state = state.copyWith(error: "All fields are required");
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.saveAddress(state.data);
      state = state.copyWith(isLoading: false, isSaved: true);
      onSuccess();
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final msg = (responseData is Map)
          ? responseData['message']
          : 'Failed to save address';
      state = state.copyWith(isLoading: false, error: msg.toString());
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "An unexpected error occurred",
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}
