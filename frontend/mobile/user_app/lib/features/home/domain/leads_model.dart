import 'package:user_app/core/utils/intl_helper.dart';

class LeadModel {
  final String id;
  final String title;
  final String description;
  final String address;
  final String city;
  final String pincode;
  final int sharingCount;
  final double originalPrice;
  final double discountedPrice;
  final String date;
  final String imageUrl;
  final bool isSharing;
  final String status;

  const LeadModel({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.city,
    required this.pincode,
    required this.sharingCount,
    required this.originalPrice,
    required this.discountedPrice,
    required this.date,
    required this.imageUrl,
    required this.isSharing,
    required this.status,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {

  final fallbackImages = [
      'https://images.unsplash.com/photo-1497366216548-37526070297c?w=200&q=60',
      'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=200&q=60',
      'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=200&q=60',
    ];

  return LeadModel(
    id: json['_id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    address: "${json['city'] ?? ''}, ${json['state'] ?? ''}",
    city: json['city'] ?? '',
    pincode: '',
    sharingCount: json['maxBuyers'] ?? 0,
    originalPrice: (json['originalPrice']?? 0).toDouble(),
    discountedPrice: (json['price'] ?? 0).toDouble(),
    date: formatIsoDate(json['createdAt']?? ''),
    imageUrl: (json['image'] == null || json['image'].toString().isEmpty)
          ? (fallbackImages.toList()..shuffle()).first
          : json['image'],
    isSharing: !(json['isPurchased'] ?? false),
    status: json['status'] ?? 'AVAILABLE',
  );
}

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'address': address,
        'city': city,
        'pincode': pincode,
        'sharing_count': sharingCount,
        'original_price': originalPrice,
        'discounted_price': discountedPrice,
        'date': date,
        'image_url': imageUrl,
        'is_sharing': isSharing,
        'status':status
      };
}