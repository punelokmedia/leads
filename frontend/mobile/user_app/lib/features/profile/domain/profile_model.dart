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
      id: json['_id'] ?? '',
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      businessName: json['businessName'] ?? '',
      workType: json['workType'] ?? '',
      cityName: json['city'] != null ? (json['city']['name'] ?? '') : '',
    );
  }

  String get fullName => '$firstname $lastname'.trim();
}