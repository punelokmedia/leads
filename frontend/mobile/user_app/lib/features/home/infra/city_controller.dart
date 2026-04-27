import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:user_app/features/home/domain/lead_category.dart' show LeadCategory;

final citySearchProvider = StateProvider<String>((ref) => "");

final cityListProvider = Provider<List<LeadCategory>>((ref) {
  final searchQuery = ref.watch(citySearchProvider).toLowerCase();
  
  // Static list based on Figma
  final allCities = [
    LeadCategory(id: '1', title: 'Instagram Reels', subtitle: 'Bengaluru, 560091', iconPath: 'reels_icon', iconColor: Colors.orange, newCount: 12, isPopular: true),
    LeadCategory(id: '2', title: 'Mumbai / Thane\nNavi Mumbai Leads', iconPath: 'loc_pin', iconColor: Colors.green, newCount: 5),
    LeadCategory(id: '3', title: 'Bengaluru Leads', iconPath: 'loc_pin', iconColor: Colors.yellow, newCount: 6),
    LeadCategory(id: '4', title: 'Hydrabad / Secundarabad Lead', iconPath: 'loc_pin', iconColor: Colors.purple, newCount: 6),
    LeadCategory(id: '5', title: 'Pune Leads', iconPath: 'loc_pin', iconColor: Colors.blue),
    LeadCategory(id: '6', title: 'Delhi / NCR Leads', iconPath: 'loc_pin', iconColor: Colors.pink),
    LeadCategory(id: '7', title: 'Kolkata Leads', iconPath: 'loc_pin', iconColor: Colors.blue),
    LeadCategory(id: '8', title: 'Chennai Leads', iconPath: 'loc_pin', iconColor: Colors.yellow),
    LeadCategory(id: '9', title: 'Lucknow Leads', iconPath: 'loc_pin', iconColor: Colors.purple),
    LeadCategory(id: '10', title: 'Ahmedabad Leads', iconPath: 'loc_pin', iconColor: Colors.orange),
    LeadCategory(id: '11', title: 'Nagpur Leads', iconPath: 'loc_pin', iconColor: Colors.green),
    LeadCategory(id: '12', title: 'Jaipur Leads', iconPath: 'loc_pin', iconColor: Colors.purple),
    LeadCategory(id: '13', title: 'Surat Leads', iconPath: 'loc_pin', iconColor: Colors.yellow),
  ];

  if (searchQuery.isEmpty) return allCities;
  return allCities.where((c) => c.title.toLowerCase().contains(searchQuery)).toList();
});
