import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/network/api_endpoints.dart';
import 'package:user_app/core/network/dio_provider.dart'; // Your dio provider
import '../domain/profile_model.dart';

abstract class IProfileRepository {
  Future<ProfileModel> fetchProfile();
  Future<void> logout();
}

class ProfileRepository implements IProfileRepository {
  final Dio _dio;
  ProfileRepository(this._dio);
  
  @override
  Future<ProfileModel> fetchProfile() async {
    // Make sure ApiEndpoints.fetchProfile points to '/auth/profile'
    final res = await _dio.get(ApiEndpoints.fetchProfile);
    return ProfileModel.fromJson(res.data['data']);
  }

  @override
  Future<void> logout() async {
    await _dio.get(ApiEndpoints.logout); 
  }
}

final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});