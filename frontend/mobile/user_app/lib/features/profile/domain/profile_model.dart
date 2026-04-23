
class ProfileModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String countryCode;
  final String address;
  final String city;
  final String? avatarUrl;

  const ProfileModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.countryCode = '+91',
    this.address = '',
    this.city = '',
    this.avatarUrl,
  });

 factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
      id: json['_id']?.toString() ?? '', 
      firstName: json['firstname'] ?? '',
      lastName: json['lastname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phoneNumber'] ?? '',
      avatarUrl: json['profilePic'],
    );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstname': firstName,     
        'lastname': lastName,
        'email': email,
        'phoneNumber': phone,
        'countryCode': countryCode,
        'address': address,
        'city': city,
        'avatar_url': avatarUrl,
      };

  ProfileModel copyWith({
    String? firstName,            
    String? lastName,
    String? email,
    String? phone,
    String? countryCode,
    String? address,
    String? city,
    String? avatarUrl,
  }) =>
      ProfileModel(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        countryCode: countryCode ?? this.countryCode,
        address: address ?? this.address,
        city: city ?? this.city,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );

  String get fullName => '$firstName $lastName'.trim();
}