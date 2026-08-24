import 'package:user_app/core/utils/intl_helper.dart';
import 'package:user_app/core/utils/media_url.dart';

class HistoryModel {
  final String id;
  final String leadType;
  final String orderId;
  final String city;
  final String customerName;
  final String time;
  final String address;
  final String phone;
  final int sharingCount;
  final String status;
  final String imageUrl;
  final bool isDownloaded;

  const HistoryModel({
    required this.id,
    required this.leadType,
    required this.orderId,
    required this.city,
    required this.customerName,
    required this.time,
    required this.address,
    required this.phone,
    required this.sharingCount,
    required this.status,
    required this.imageUrl,
    required this.isDownloaded,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    final fallbackImages = [
      'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=200',
      'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=200',
      'https://images.unsplash.com/photo-1497366216548-37526070297c?w=200',
    ];

    return HistoryModel(
      // Item level fields
      id: json['leadId']?.toString() ?? '', 
      leadType: json['title'] ?? 'Lead',
      city: json['city'] ?? 'N/A',
      customerName: json['customerName'] ?? 'Customer',
      address: json['address'] ?? '',
      phone: json['phone']?.toString() ?? '',
      sharingCount: json['quantity'] ?? 1, // ✅ Mapped from 'quantity'
      
      // Order level fields (merged from parent)
      orderId: json['orderId']?.toString() ?? '',
      time: formatIsoDate(json['paidAt'] ?? ''), // ✅ Mapped from 'paidAt'
      status: json['status'] ?? 'PAID',
      isDownloaded: json['isDownloaded'] ?? false,
      
      imageUrl: MediaUrl.resolve(json['image']?.toString()) ??
          (fallbackImages.toList()..shuffle()).first,
    );
  }
}