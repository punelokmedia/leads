enum AddressType { home, office }

class AddressModel {
  final String? id;
  final String flatStreet;
  final String landmark;
  final String city;
  final String state;
  final String zipcode;
  final AddressType type;

  const AddressModel({
    this.id,
    required this.flatStreet,
    required this.landmark,
    required this.city,
    required this.state,
    required this.zipcode,
    this.type = AddressType.home,
  });

  factory AddressModel.empty() => const AddressModel(
    flatStreet: '',
    landmark: '',
    city: '',
    state: '',
    zipcode: '',
    type: AddressType.home,
  );

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
    id: json['_id'] as String?,
    flatStreet: json['street'] as String? ?? '',
    landmark: json['landmark'] as String? ?? '',
    city: json['city'] as String? ?? '',
    state: json['state'] as String? ?? '',
    zipcode: json['zipcode'] as String? ?? '',
    type: (json['label'] as String?)?.toLowerCase() == 'office'
        ? AddressType.office
        : AddressType.home,
  );

  Map<String, dynamic> toJson() => {
    'label': type.name.toUpperCase(), 
    'street': flatStreet, 
    'landmark': landmark,
    'city': city,
    'state': state,
    'zipcode': zipcode,
  };

  AddressModel copyWith({
    String? flatStreet,
    String? landmark,
    String? city,
    String? state,
    String? zipcode,
    AddressType? type,
  }) => AddressModel(
    id: id,
    flatStreet: flatStreet ?? this.flatStreet,
    landmark: landmark ?? this.landmark,
    city: city ?? this.city,
    state: state ?? this.state,
    zipcode: zipcode ?? this.zipcode,
    type: type ?? this.type,
  );
}

class AddressState {
  final AddressModel data;
  final bool isLoading;
  final String? error;
  final bool isSaved;

  const AddressState({
    required this.data,
    this.isLoading = false,
    this.error,
    this.isSaved = false,
  });

  AddressState copyWith({
    AddressModel? data,
    bool? isLoading,
    String? error,
    bool? isSaved,
    bool clearError = false,
  }) => AddressState(
    data: data ?? this.data,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
    isSaved: isSaved ?? this.isSaved,
  );
}
