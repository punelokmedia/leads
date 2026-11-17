import 'package:user_app/core/utils/intl_helper.dart';
import '../../preview/category_media.dart';

class CartLead {
  final String id;
  final String title;
  final String location;
  final String name;
  final String address;
  final String time;
  final String sharingCount;
  final String? imageUrl;
  final bool isSelected;
  final int quantity;
  final num? price;

  const CartLead({
    required this.id,
    required this.title,
    required this.location,
    required this.name,
    required this.address,
    required this.time,
    required this.sharingCount,
    this.imageUrl,
    this.isSelected = true,
    this.quantity = 1,
    this.price,
  });

  CartLead copyWith({bool? isSelected, int? quantity}) => CartLead(
    id: id,
    title: title,
    location: location,
    name: name,
    address: address,
    time: time,
    sharingCount: sharingCount,
    imageUrl: imageUrl,
    isSelected: isSelected ?? this.isSelected,
    quantity: quantity ?? this.quantity,
    price: price,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'location': location,
    'name': name,
    'address': address,
    'time': time,
    'sharingCount': sharingCount,
    'imageUrl': imageUrl,
    'isSelected': isSelected,
    'quantity': quantity,
    'price': price,
  };

  factory CartLead.fromJson(Map<String, dynamic> j) {
    final id = (j['id'] ?? j['_id'] ?? '').toString();
    final displayId =
        j['leadDisplayId']?.toString() ??
        'NL${id.substring(id.length > 8 ? id.length - 8 : 0).toUpperCase()}';
    return CartLead(
      // Map '_id' from backend to 'id'
      id: id,
      title: j['title'] ?? '',
      // Map 'city' + 'state' from backend to 'location'
      location: "${j['city'] ?? ''}, ${j['state'] ?? ''}",
      // Handle missing fields with defaults
      name: j['name'] ?? j['title'] ?? '',
      address: j['address'] ?? j['city'] ?? '',
      time: formatIsoDate(j['expiresAt'] ?? j['time'] ?? ''),
      sharingCount:
          j['sharingCount']?.toString() ??
          j['remainingSlots']?.toString() ??
          '0',
      imageUrl:
          j['imageUrl'] ??
          CategoryMedia.getLeadImage(
            j['category'] is Map
                ? (j['category']['displayName'] ?? j['category']['name'])
                      ?.toString()
                : (j['categoryName'] ?? j['title'])?.toString(),
            leadId: displayId,
          ),
      isSelected: j['isSelected'] ?? true,
      quantity: j['quantity'] ?? 1,
      price: j['price'] is num ? j['price'] as num : null,
    );
  }
}

// cart_model.dart (or wherever your CartState is defined)
class CartState {
  final List<CartLead> items;
  final bool isLoading;
  final String? error;
  final List<String> availabilityMessages;
  final String? activeInternalOrderId;
  final Map<String, dynamic>? lastOrderDetails; // <--- Add this

  const CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.availabilityMessages = const [],
    this.lastOrderDetails,
    this.activeInternalOrderId,
  });

  CartState copyWith({
    List<CartLead>? items,
    bool? isLoading,
    String? error,
    List<String>? availabilityMessages,
    Map<String, dynamic>? lastOrderDetails,
    String? activeInternalOrderId,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      availabilityMessages: availabilityMessages ?? this.availabilityMessages,
      activeInternalOrderId:
          activeInternalOrderId ?? this.activeInternalOrderId,
      lastOrderDetails: lastOrderDetails ?? this.lastOrderDetails,
    );
  }
}
