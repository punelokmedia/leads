import 'dart:convert';

import 'package:user_app/core/utils/intl_helper.dart';

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
  });

  CartLead copyWith({bool? isSelected,int? quantity,}) => CartLead(
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
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'location': location, 'name': name,
        'address': address, 'time': time, 'sharingCount': sharingCount,
        'imageUrl': imageUrl, 'isSelected': isSelected,'quantity': quantity,
      };

  factory CartLead.fromJson(Map<String, dynamic> j) => CartLead(
      // Map '_id' from backend to 'id'
      id: (j['id'] ?? j['_id'] ?? '').toString(), 
      title: j['title'] ?? '',
      // Map 'city' + 'state' from backend to 'location'
      location: "${j['city'] ?? ''}, ${j['state'] ?? ''}", 
      // Handle missing fields with defaults
      name: j['name'] ?? j['title'] ?? '', 
      address: j['address'] ?? j['city'] ?? '',
      time: formatIsoDate(j['expiresAt'] ?? j['time'] ?? ''),
      sharingCount: j['sharingCount']?.toString() ?? j['remainingSlots']?.toString() ?? '0',
      imageUrl: j['imageUrl'],
      isSelected: j['isSelected'] ?? true,
      quantity: j['quantity'] ?? 1,
    );
}

// cart_model.dart (or wherever your CartState is defined)
class CartState {
  final List<CartLead> items;
  final bool isLoading;
  final String? error;
  final String? activeInternalOrderId;
  final Map<String, dynamic>? lastOrderDetails; // <--- Add this

  const CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.lastOrderDetails,
    this.activeInternalOrderId,
  });

  CartState copyWith({
    List<CartLead>? items,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? lastOrderDetails,
    String? activeInternalOrderId,
  }) {

    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeInternalOrderId: activeInternalOrderId ?? this.activeInternalOrderId,
      lastOrderDetails: lastOrderDetails ?? this.lastOrderDetails,
    );
  }
}