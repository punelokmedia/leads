import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/auth/infra/google_sign_in_error.dart';

void main() {
  test('release-obfuscated Google exception keeps its actionable status', () {
    final error = googleSignInError(PlatformException(
      code: 'sign_in_failed',
      message: 'a.b.c: 12500: private account details',
    ));
    expect(error.message, contains('Google status 12500'));
    expect(error.message, isNot(contains('private account details')));
  });

  test('configuration and network errors are distinguished', () {
    for (final status in ['10', '7']) {
      final error = googleSignInError(PlatformException(
        code: 'sign_in_failed', message: 'ApiException: $status: ',
      ));
      expect(error.message, contains('($status)'));
    }
  });

  test('missing native status and cancellation are handled', () {
    expect(googleSignInError(PlatformException(code: 'sign_in_failed')).message,
        contains('(sign_in_failed)'));
    expect(googleSignInError(PlatformException(code: 'sign_in_canceled')).message,
        'Google Sign-In canceled');
  });
}
