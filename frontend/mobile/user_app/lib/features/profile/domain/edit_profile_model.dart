import 'package:user_app/features/profile/domain/profile_model.dart';

class EditProfileModel {
  final String firstName;
  final String lastName;
  final String countryCode;
  final String phone;
  final String address;
  final String city;
  final String email;
  final String? avatarUrl;

  const EditProfileModel({
    required this.firstName,
    required this.lastName,
    required this.countryCode,
    required this.phone,
    required this.address,
    required this.city,
    required this.email,
    this.avatarUrl,
  });

  // ── From API response ──────────────────────────────────────────────────────
  factory EditProfileModel.fromJson(Map<String, dynamic> json) {
  final addressData = json['address'] as Map<String, dynamic>?;

  return EditProfileModel(
    firstName: json['firstname'] as String? ?? '',
    lastName: json['lastname'] as String? ?? '',
    countryCode: json['countryCode'] as String? ?? '+91',
    phone: json['phoneNumber'] as String? ?? '',
    address: addressData?['street'] as String? ?? '',
    city: addressData?['city'] as String? ?? '',
    email: json['email'] as String? ?? '',
    avatarUrl: json['profilePic'] as String?,
  );
}

  // ── Convert from ProfileModel ──────────────────────────────────────────────
  factory EditProfileModel.fromProfile(ProfileModel p) => EditProfileModel(
        firstName:   p.firstName,
        lastName:    p.lastName,
        countryCode: p.countryCode,
        phone:       p.phone,
        address:     p.address,
        city:        p.city,
        email:       p.email,
        avatarUrl:   p.avatarUrl,
      );

  // ── To API request body ────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'firstname':   firstName,
        'lastname':    lastName,
        'countryCode': countryCode,
        'phoneNumber': phone,
        'address':     address,
        'city':        city,
        'email':       email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

  EditProfileModel copyWith({
    String? firstName,
    String? lastName,
    String? countryCode,
    String? phone,
    String? address,
    String? city,
    String? email,
    String? avatarUrl,
  }) =>
      EditProfileModel(
        firstName:   firstName   ?? this.firstName,
        lastName:    lastName    ?? this.lastName,
        countryCode: countryCode ?? this.countryCode,
        phone:       phone       ?? this.phone,
        address:     address     ?? this.address,
        city:        city        ?? this.city,
        email:       email       ?? this.email,
        avatarUrl:   avatarUrl   ?? this.avatarUrl,
      );

  String get fullName => '$firstName $lastName'.trim();
}

// ── Available cities ───────────────────────────────────────────────────────────
const List<String> kAvailableCities = [
  'Select City',
  'Bangalore',
  'Chennai',
  'Hyderabad',
  'Mumbai',
  'Pune',
  'Delhi',
  'Kolkata',
  'Nagpur',
  'Coimbatore',
];