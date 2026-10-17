import 'package:flutter/services.dart';
import 'package:user_app/core/errors/app_exception.dart';

AppException googleSignInError(PlatformException error) {
  // R8 can rename ApiException in release builds. Match the numeric status,
  // without relying on the Java class name or exposing provider/account data.
  final status = RegExp(r':\s*(\d+)\s*:')
      .firstMatch(error.message ?? '')
      ?.group(1);
  if (error.code == 'sign_in_canceled') {
    return const AppException('Google Sign-In canceled');
  }
  if (status == '10') {
    return const AppException(
      'Google sign-in configuration error (10). Check the Android package, '
      'release SHA-1 and Web client ID in Google Cloud.',
    );
  }
  if (status == '7' || error.code == 'network_error') {
    return const AppException(
      'Google sign-in could not connect to Google (7). Check your connection '
      'and try again.',
    );
  }
  return AppException(
    'Google account sign-in failed (${error.code}'
    '${status == null ? '' : '; Google status $status'}). '
    'Please report this code.',
  );
}
