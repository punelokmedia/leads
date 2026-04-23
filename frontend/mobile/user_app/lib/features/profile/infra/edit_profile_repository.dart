import 'package:dio/dio.dart';
import 'package:user_app/core/network/api_endpoints.dart';

import '../domain/edit_profile_model.dart';

abstract class IEditProfileRepository {
  Future<EditProfileModel> fetchEditProfile();
  Future<void> updateProfile(EditProfileModel model);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class EditProfileRepository implements IEditProfileRepository {
  final Dio _dio;
  EditProfileRepository(this._dio);

  @override
  Future<EditProfileModel> fetchEditProfile() async {
    final res = await _dio.get(ApiEndpoints.fetchProfile);
    return EditProfileModel.fromJson(res.data['data']);
  }

  @override
  Future<void> updateProfile(EditProfileModel model) async {
    await _dio.put(
      ApiEndpoints.editProfile,
      data: model.toJson(),
    );
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _dio.post(
      ApiEndpoints.changePassword,
      data: {
        'oldPassword': currentPassword, 
        'newPassword': newPassword,
        'confirmPassword': newPassword,
      },
    );
  }
}