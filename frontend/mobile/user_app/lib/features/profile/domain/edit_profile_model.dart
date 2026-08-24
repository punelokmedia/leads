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
    Map<String, dynamic>? addressData;
    final rawAddress = json['address'];
    if (rawAddress is Map<String, dynamic>) {
      addressData = rawAddress;
    }

    final cityFromUser = json['city'];
    String city = '';
    if (cityFromUser is Map) {
      city = cityFromUser['name']?.toString() ?? '';
    } else if (cityFromUser is String) {
      city = cityFromUser;
    }
    if (city.isEmpty) {
      city = addressData?['city']?.toString() ?? '';
    }

    return EditProfileModel(
      firstName: json['firstname']?.toString() ?? '',
      lastName: json['lastname']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? '+91',
      phone: json['phoneNumber']?.toString() ?? '',
      address: addressData?['street']?.toString() ??
          (rawAddress is String ? rawAddress : ''),
      city: city,
      email: json['email']?.toString() ?? '',
      avatarUrl: json['profilePic']?.toString(),
    );
  }

  // ── Convert from ProfileModel ──────────────────────────────────────────────
  factory EditProfileModel.fromProfile(ProfileModel p) => EditProfileModel(
        firstName:   p.firstname,       // ✅ Fixed: Maps to p.firstname
        lastName:    p.lastname,        // ✅ Fixed: Maps to p.lastname
        countryCode: '+91',             // ✅ Added Fallback
        phone:       p.phoneNumber,     // ✅ Fixed: Maps to p.phoneNumber
        address:     p.address,         
        city:        p.cityName,        // ✅ Fixed: Maps to p.cityName
        email:       p.email,
        avatarUrl:   null,              // ✅ Added Fallback
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