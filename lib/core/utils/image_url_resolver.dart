import '../network/api_config.dart';

class ImageUrlResolver {
  ImageUrlResolver._();

  /// The API returns media as a root-relative path; an <img> needs the host.
  static String resolve(String path) {
    final String trimmed = path.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final String base = ApiConfig.baseUrl;
    if (base.isEmpty) return trimmed;

    return trimmed.startsWith('/') ? '$base$trimmed' : '$base/$trimmed';
  }
}
