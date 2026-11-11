class CategoryMedia {
  static const Map<String, String> _folderNames = {
    'pop': '(POP) False Ceiling Work',
    'false ceiling': '(POP) False Ceiling Work',
    'ceiling': '(POP) False Ceiling Work',
    'ac': 'AC Service & Repair',
    'air condition': 'AC Service & Repair',
    'aluminium': 'Aluminium & Windows',
    'window': 'Aluminium & Windows',
    'cctv': 'CCTV Installation',
    'civil': 'Civil Work',
    'renovation': 'Civil Work',
    'home renovation': 'Civil Work',
    'architecture': 'Civil Work',
    'flooring': 'Civil Work',
    'landscaping': 'Civil Work',
    'construction': 'Construction Enquiry',
    'electric': 'Electrical Work',
    'mep': 'Electrical Work',
    'home automation': 'Electrical Work',
    'interior': 'Interior Design',
    'modular': 'Interior Design',
    'carpentry': 'Interior Design',
    'furniture': 'Interior Design',
    'kitchen': 'Interior Design',
    'paint': 'Painting',
    'plumb': 'Plumbing',
    'real estate': 'Real State',
    'real state': 'Real State',
    'property': 'Real State',
    'waterproof': 'Water Proofing',
    'water proofing': 'Water Proofing',
  };

  static String? getCategoryFolder(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final lower = name.toLowerCase().trim();
    for (final entry in _folderNames.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Returns a mobile-sized project photo mapped to a lead.
  static String getLeadImage(
    String? categoryName, {
    String? leadId,
    int index = 0,
  }) {
    final folder = getCategoryFolder(categoryName);
    if (folder == null) {
      return 'assets/branding/hero.webp';
    }
    final variant = (leadId != null && leadId.isNotEmpty)
        ? (leadId.hashCode.abs() % 3) + 1
        : (index.abs() % 3) + 1;
    return 'assets/$folder/0$variant.jpg';
  }

  /// Returns the main category cover image (e.g. Painting.jpg).
  static String? getCategoryCover(String? categoryName) {
    final folder = getCategoryFolder(categoryName);
    if (folder == null) return null;
    return 'assets/$folder/$folder.jpg';
  }

  /// Returns the three project photos and cover for a category.
  static List<String> getProjectImages(String? categoryName) {
    final folder = getCategoryFolder(categoryName);
    if (folder == null) {
      return const ['assets/branding/hero.webp'];
    }
    return [
      'assets/$folder/01.jpg',
      'assets/$folder/02.jpg',
      'assets/$folder/03.jpg',
      'assets/$folder/$folder.jpg',
    ];
  }
}
