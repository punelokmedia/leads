// features/auth/shared/profile_draft_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';

class ProfileDraft {
  final String fullName;
  final String email;
  final String businessName;
  final String city;
  final String cityId; // ✅ Added cityId
  final String workType;
  final List<String> categories;

  ProfileDraft({
    this.fullName = '',
    this.email = '',
    this.businessName = '',
    this.city = '',
    this.cityId = '', // ✅ Initialize
    this.workType = '',
    this.categories = const [],
  });

  ProfileDraft copyWith({
    String? fullName,
    String? email,
    String? businessName,
    String? city,
    String? cityId, // ✅ Added to copyWith
    String? workType,
    List<String>? categories,
  }) {
    return ProfileDraft(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      businessName: businessName ?? this.businessName,
      city: city ?? this.city,
      cityId: cityId ?? this.cityId, // ✅ Store it
      workType: workType ?? this.workType,
      categories: categories ?? this.categories,
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
    String cityId = '', // Optional, in case first screen doesn't have ID yet
    required String workType,
  }) {
    state = state.copyWith(
      fullName: fullName,
      email: email,
      businessName: businessName,
      city: city,
      cityId: cityId.isNotEmpty ? cityId : state.cityId,
      workType: workType,
    );
  }

  // ✅ Updated to accept both name and ID
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