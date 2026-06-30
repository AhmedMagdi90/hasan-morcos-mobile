import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String defaultBaseUrl = 'http://192.168.1.47:8000';
  static const String _storageKey = 'api_base_url';
  static String baseUrl = defaultBaseUrl;

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedUrl = preferences.getString(_storageKey);

    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      baseUrl = _normalize(savedUrl);
    }
  }

  static Future<void> saveBaseUrl(String url) async {
    final normalizedUrl = _normalize(url);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, normalizedUrl);
    baseUrl = normalizedUrl;
  }

  static String _normalize(String url) {
    final trimmedUrl = url.trim();

    if (trimmedUrl.endsWith('/')) {
      return trimmedUrl.substring(0, trimmedUrl.length - 1);
    }

    return trimmedUrl;
  }

  static String absoluteUrl(String path) {
    if (path.isEmpty) {
      return '';
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    if (path.startsWith('/')) {
      return '$baseUrl$path';
    }

    return '$baseUrl/$path';
  }
}
