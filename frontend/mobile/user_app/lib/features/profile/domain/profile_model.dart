class ProfileModel {
  final String id;
  final String firstname;
  final String lastname;
  final String email;
  final String phoneNumber;
  final String businessName;
  final String workType;
  final String cityName;
  
  // These aren't in the API response yet, using defaults for UI
  final String gstNumber; 
  final String address; 

  ProfileModel({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.phoneNumber,
    required this.businessName,
    required this.workType,
    required this.cityName,
    this.gstNumber = 'Not Available', 
    this.address = 'Not Available',   
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['_id']?.toString() ?? '',
      firstname: json['firstname']?.toString() ?? '',
      lastname: json['lastname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      businessName: json['businessName']?.toString() ?? '',
      workType: json['workType']?.toString() ?? '',
      cityName: _readCityName(json['city']),
      address: _readAddress(json['address']),
    );
  }

  static String _readCityName(dynamic city) {
    if (city is Map) return city['name']?.toString() ?? '';
    if (city is String) return city;
    return '';
  }

  static String _readAddress(dynamic address) {
    if (address is Map) {
      final street = address['street']?.toString() ?? '';
      final city = address['city']?.toString() ?? '';
      final combined = [street, city].where((part) => part.isNotEmpty).join(', ');
      return combined.isEmpty ? 'Not Available' : combined;
    }
    if (address is String && address.trim().isNotEmpty) return address;
    return 'Not Available';
  }

  String get fullName => '$firstname $lastname'.trim();
}