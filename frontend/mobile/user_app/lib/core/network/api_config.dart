class ApiConfig {
  ApiConfig._();

  // Local development must explicitly pass --dart-define=BASE_URL=...
  static const String _configuredUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://leads-qa6h.vercel.app/',
  );

  static String get baseUrl {
    final value = _configuredUrl.trim();
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw StateError('BASE_URL must be an absolute HTTP or HTTPS URL.');
    }
    return value.endsWith('/') ? value : '$value/';
  }
}
