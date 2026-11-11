import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/preview/category_media.dart';

void main() {
  test('every category resolves to existing optimized photos', () {
    const categories = [
      'POP', 'AC', 'Aluminium', 'CCTV', 'Civil', 'Construction',
      'Electrical', 'Interior', 'Painting', 'Plumbing', 'Real State',
      'Water Proofing',
    ];
    for (final category in categories) {
      final photos = CategoryMedia.getProjectImages(category);
      expect(photos, hasLength(4));
      for (final path in photos) {
        expect(File(path).existsSync(), isTrue, reason: path);
        expect(File(path).lengthSync(), lessThan(1024 * 1024), reason: path);
      }
      expect(photos, contains(CategoryMedia.getCategoryCover(category)));
      expect(photos, contains(CategoryMedia.getLeadImage(category, leadId: 'sample')));
    }
    expect(File(CategoryMedia.getLeadImage(null)).existsSync(), isTrue);
  });
}
