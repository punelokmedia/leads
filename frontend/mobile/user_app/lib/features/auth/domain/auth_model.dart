// auth/domain/auth_model.dart

class AuthUser {
  final String id;
  final String firstname;
  final String lastname;
  final String email;
  final String? phoneNumber;
  final String role;
  final String? provider;
  final bool registrationFeePaid;
  final String city;
  final String businessName;
  final String workType;
  bool get isProfileComplete =>
      fullName.isNotEmpty &&
      email.isNotEmpty &&
      city.isNotEmpty &&
      businessName.isNotEmpty &&
      workType.isNotEmpty;

  const AuthUser({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.provider,
    this.registrationFeePaid = false,
    this.city = '',
    this.businessName = '',
    this.workType = '',
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['_id'] ?? json['id'] ?? '',
    firstname: json['firstname'] ?? '',
    lastname: json['lastname'] ?? '',
    email: json['email'] ?? '',
    phoneNumber: json['phoneNumber'],
    role: json['role'] ?? 'USER',
    provider: json['provider'],
    registrationFeePaid: json['registrationFeePaid'] == true,
    city: json['city']?.toString() ?? '',
    businessName: json['businessName'] ?? '',
    workType: json['workType'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'firstname': firstname,
    'lastname': lastname,
    'email': email,
    'phoneNumber': phoneNumber,
    'role': role,
    'provider': provider,
    'registrationFeePaid': registrationFeePaid,
    'city': city,
    'businessName': businessName,
    'workType': workType,
  };

  String get fullName => '$firstname $lastname'.trim();

  // ✅ FIX: Added the missing getter so `.phone` works seamlessly
  String? get phone => phoneNumber;
}

class AuthState {
  final bool isLoading;
  final String? error;
  final AuthUser? user;
  final String? token;

  const AuthState({this.isLoading = false, this.error, this.user, this.token});

  AuthState copyWith({
    bool? isLoading,
    String? error,
    AuthUser? user,
    String? token,
    bool clearError = false,
    bool clearToken = false,
  }) => AuthState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
    user: user ?? this.user,
    token: clearToken ? null : token ?? this.token,
  );
}
