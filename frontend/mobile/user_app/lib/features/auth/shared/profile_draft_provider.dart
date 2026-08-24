// features/auth/shared/profile_draft_provider.dart
import 'package:hooks_riverpod/legacy.dart';

class ProfileDraft {
  final String fullName;
  final String email;
  final String businessName;
  final String city;
  final String cityId;
  final String address;
  final String workType;
  final List<String> categories;
  final String profilePicPath; // ✅ ADDED

  ProfileDraft({
    this.fullName = '',
    this.email = '',
    this.businessName = '',
    this.city = '',
    this.cityId = '',
    this.workType = '',
    this.address = '',
    this.categories = const [],
    this.profilePicPath = '', // ✅ ADDED
  });

  ProfileDraft copyWith({
    String? fullName,
    String? email,
    String? businessName,
    String? city,
    String? cityId, 
    String? address,
    String? workType,
    List<String>? categories,
    String? profilePicPath, // ✅ ADDED
  }) {
    return ProfileDraft(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      businessName: businessName ?? this.businessName,
      city: city ?? this.city,
      cityId: cityId ?? this.cityId, 
      workType: workType ?? this.workType,
      categories: categories ?? this.categories,
      address: address ?? this.address,
      profilePicPath: profilePicPath ?? this.profilePicPath, // ✅ ADDED
    );
  }
}

class ProfileDraftNotifier extends StateNotifier<ProfileDraft> {
  ProfileDraftNotifier() : super(ProfileDraft());

  void updateBasicDetails({
    required String fullName,
    required String email,
    required String businessName,
    required String city,
    String cityId = '', 
    required String workType,
    required String address,
    required String profilePicPath, 
  }) {
    state = state.copyWith(
      fullName: fullName,
      email: email,
      businessName: businessName,
      city: city,
      cityId: cityId.isNotEmpty ? cityId : state.cityId,
      workType: workType,
      address: address,
      profilePicPath: profilePicPath, 
    );
  }

  void updateCity({required String cityName, required String cityId}) {
    state = state.copyWith(city: cityName, cityId: cityId);
  }

  void updateCategories(List<String> categories) =>
      state = state.copyWith(categories: categories);

  void clearDraft() => state = ProfileDraft();
}

final profileDraftProvider =
    StateNotifierProvider<ProfileDraftNotifier, ProfileDraft>((ref) {
  return ProfileDraftNotifier();
});