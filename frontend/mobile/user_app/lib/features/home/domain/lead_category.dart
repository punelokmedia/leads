import 'dart:ui';

class LeadCategory {
  final String id;
  final String title;
  final String? subtitle;
  final String iconPath;
  final int? newCount;
  final Color iconColor;
  final bool isPopular;

  LeadCategory({
    required this.id,
    required this.title,
    this.subtitle,
    required this.iconPath,
    this.newCount,
    required this.iconColor,
    this.isPopular = false,
  });
}