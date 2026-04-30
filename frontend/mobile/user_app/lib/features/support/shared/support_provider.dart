// features/support/shared/support_providers.dart
import 'package:hooks_riverpod/legacy.dart';

final termsAgreementProvider = StateProvider.autoDispose<bool>((ref) => false);
