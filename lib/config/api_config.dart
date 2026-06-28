class ApiConfig {
  static const String baseUrl = 'http://192.168.1.47:8000';

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
