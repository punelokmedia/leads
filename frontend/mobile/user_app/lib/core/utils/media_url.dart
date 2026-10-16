import '../network/api_config.dart';

class MediaUrl {
  static String get _baseUrl {
    return ApiConfig.baseUrl;
  }

  static bool isSvg(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final value = url.toLowerCase();
    return value.contains('.svg') ||
        value.contains('/svg?') ||
        value.contains('/svg/') ||
        value.contains('image/svg');
  }

  static bool isHttpUrl(String? url) {
    if (url == null) return false;
    final value = url.trim().toLowerCase();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static String? resolve(String? url) {
    if (url == null) return null;
    var value = url.trim();
    if (value.isEmpty || value.toLowerCase() == 'null') return null;

    final base = Uri.parse(_baseUrl);

    if (value.startsWith('/')) {
      value = base.resolve(value.substring(1)).toString();
    } else if (!isHttpUrl(value)) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return null;

    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      return uri
          .replace(
            host: base.host,
            port: base.hasPort ? base.port : uri.port,
          )
          .toString();
    }

    return uri.toString();
  }
}
