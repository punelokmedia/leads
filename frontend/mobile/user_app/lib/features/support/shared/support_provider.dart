// features/support/shared/support_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';


final termsAgreementProvider = StateProvider.autoDispose<bool>((ref) => false);