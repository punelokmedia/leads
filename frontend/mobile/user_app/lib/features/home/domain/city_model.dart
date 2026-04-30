class CityModel {
  final String id;
  final String name;

  const CityModel({required this.id, required this.name});

  String get displayName =>
      name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(id: json['_id'] as String, name: json['name'] as String);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CityModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
