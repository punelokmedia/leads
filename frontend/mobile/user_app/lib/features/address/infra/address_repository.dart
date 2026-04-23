// address/infra/address_repository.dart

import 'package:dio/dio.dart';
import 'package:user_app/core/network/api_endpoints.dart';
import '../domain/address_model.dart';

class AddressRepository {
  final Dio _dio;
  AddressRepository(this._dio);

  /// POST /user/add-address
  Future<AddressModel> saveAddress(AddressModel address) async {
    final res = await _dio.post(
      ApiEndpoints.addAddress,
      data: address.toJson(),
    );
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return AddressModel.fromJson(data);
  }

  /// GET /user/addresses
  Future<List<AddressModel>> getAddresses() async {
    final res = await _dio.get('/user/addresses');
    final body = res.data as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    return list
        .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}