import 'package:http/http.dart' as http;

import '../utils/content_parser.dart';

class LinkPreviewService {
  Future<String?> coverFor(String input) async {
    final youtube = ContentParser.youtubeThumbnailUrl(input);
    if (youtube != null) return youtube;

    final url = ContentParser.extractFirstUrl(input);
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) return null;

    try {
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'Vaultly/1.0 link preview',
          'Accept': 'text/html,application/xhtml+xml',
        },
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode < 200 || response.statusCode >= 400) return null;
      return _extractOgImage(response.body, uri);
    } catch (_) {
      return null;
    }
  }

  String? _extractOgImage(String html, Uri pageUri) {
    final patterns = [
      RegExp(
        r'''<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']''',
        caseSensitive: false,
      ),
      RegExp(
        r'''<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']''',
        caseSensitive: false,
      ),
      RegExp(
        r'''<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)["']''',
        caseSensitive: false,
      ),
      RegExp(
        r'''<meta[^>]+name=["']twitter:image:src["'][^>]+content=["']([^"']+)["']''',
        caseSensitive: false,
      ),
      RegExp(
        r'''<meta[^>]+itemprop=["']image["'][^>]+content=["']([^"']+)["']''',
        caseSensitive: false,
      ),
      RegExp(
        r'''<link[^>]+rel=["']image_src["'][^>]+href=["']([^"']+)["']''',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      final raw = match?.group(1);
      if (raw == null || raw.isEmpty) continue;
      return pageUri.resolve(_decodeHtml(raw)).toString();
    }
    return null;
  }

  String _decodeHtml(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }
}
