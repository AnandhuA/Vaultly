import '../../data/models/source_app.dart';
import '../../data/models/vault_item.dart';

class ParsedContent {
  const ParsedContent({
    required this.rawText,
    required this.title,
    required this.description,
    required this.source,
    required this.itemType,
    required this.tags,
    this.url,
    this.suggestedCollection,
    this.localFilePath,
    this.coverImageUrl,
    this.confidence = 1,
  });

  final String rawText;
  final String title;
  final String description;
  final String? url;
  final SourceApp source;
  final VaultItemType itemType;
  final String? suggestedCollection;
  final List<String> tags;
  final String? localFilePath;
  final String? coverImageUrl;
  final double confidence;

  bool get needsReview => suggestedCollection == null || confidence < 0.72;
}

class ContentParser {
  static ParsedContent parseSharedText(String text, {String? filePath, String? typeHint}) {
    final raw = text.trim();
    final url = extractFirstUrl(raw);
    final target = url ?? raw;
    final source = detectSource(target);
    final type = detectItemType(target, typeHint: typeHint);
    final suggested = suggestCollection(raw);
    final title = _generateTitle(raw, url, source, type);
    return ParsedContent(
      rawText: raw,
      title: title,
      description: _shortDescription(raw),
      url: _isLinkType(type) ? url ?? raw : null,
      source: source,
      itemType: type,
      suggestedCollection: suggested,
      tags: generateTags(raw),
      localFilePath: filePath,
      coverImageUrl: _localCover(filePath, typeHint) ?? youtubeThumbnailUrl(url ?? raw),
      confidence: suggested == null ? 0.45 : 0.86,
    );
  }

  static String? youtubeThumbnailUrl(String input) {
    final id = youtubeVideoId(input);
    if (id == null) return null;
    return 'https://img.youtube.com/vi/$id/maxresdefault.jpg';
  }

  static String? youtubeVideoId(String input) {
    final uri = Uri.tryParse(extractFirstUrl(input) ?? input);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    }
    if (host.contains('youtube.com')) {
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) return v;
      final shortsIndex = uri.pathSegments.indexOf('shorts');
      if (shortsIndex >= 0 && uri.pathSegments.length > shortsIndex + 1) {
        return uri.pathSegments[shortsIndex + 1];
      }
      final embedIndex = uri.pathSegments.indexOf('embed');
      if (embedIndex >= 0 && uri.pathSegments.length > embedIndex + 1) {
        return uri.pathSegments[embedIndex + 1];
      }
    }
    return null;
  }

  static String? extractFirstUrl(String text) {
    final match = RegExp(r'https?:\/\/[^\s]+|www\.[^\s]+', caseSensitive: false).firstMatch(text);
    if (match == null) return null;
    final url = match.group(0)!.replaceAll(RegExp(r'[),.]+$'), '');
    return url.startsWith('www.') ? 'https://$url' : url;
  }

  static SourceApp detectSource(String urlOrText) {
    final lower = urlOrText.toLowerCase();
    if (lower.contains('instagram.com')) return SourceApp.instagram;
    if (lower.contains('linkedin.com')) return SourceApp.linkedin;
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) return SourceApp.youtube;
    if (lower.contains('wa.me') || lower.contains('whatsapp.com')) return SourceApp.whatsapp;
    if (lower.contains('t.me') || lower.contains('telegram.me')) return SourceApp.telegram;
    if (lower.startsWith('http://') || lower.startsWith('https://')) return SourceApp.browser;
    return SourceApp.unknown;
  }

  static VaultItemType detectItemType(String urlOrText, {String? typeHint}) {
    final lower = urlOrText.toLowerCase();
    if (typeHint == 'image' || _endsWithAny(lower, ['.png', '.jpg', '.jpeg', '.webp'])) {
      return VaultItemType.image;
    }
    if (typeHint == 'video' || _endsWithAny(lower, ['.mp4', '.mov', '.mkv', '.webm'])) {
      return VaultItemType.video;
    }
    if (typeHint == 'pdf' || lower.endsWith('.pdf')) return VaultItemType.pdf;
    if (typeHint == 'note') return VaultItemType.note;
    if (lower.contains('instagram.com')) return VaultItemType.instagram;
    if (lower.contains('linkedin.com')) return VaultItemType.linkedin;
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) return VaultItemType.youtube;
    if (lower.startsWith('http://') || lower.startsWith('https://') || lower.startsWith('www.')) {
      return VaultItemType.link;
    }
    if (typeHint == 'document' || _endsWithAny(lower, ['.doc', '.docx', '.txt'])) {
      return VaultItemType.document;
    }
    return VaultItemType.text;
  }

  static String? suggestCollection(String titleOrUrl) {
    final lower = titleOrUrl.toLowerCase();
    if (_containsAny(lower, ['flutter', 'dart', 'firebase', 'provider', 'bloc', 'riverpod'])) {
      return 'Flutter';
    }
    if (_containsAny(lower, ['job', 'career', 'hiring', 'resume', 'interview'])) return 'Career';
    if (_containsAny(lower, ['ui', 'design', 'figma', 'animation', 'inspiration'])) {
      return 'UI Inspiration';
    }
    if (_containsAny(lower, ['money', 'bill', 'invoice', 'tax', 'payment'])) return 'Finance';
    if (_containsAny(lower, ['travel', 'hotel', 'ticket', 'trip'])) return 'Travel';
    if (_containsAny(lower, ['recipe', 'food', 'cooking'])) return 'Recipes';
    return null;
  }

  static List<String> generateTags(String titleOrUrl) {
    final lower = titleOrUrl.toLowerCase();
    final tags = <String>[];
    final candidates = {
      'flutter': ['flutter', 'dart', 'provider', 'bloc', 'riverpod'],
      'career': ['job', 'career', 'hiring', 'resume', 'interview'],
      'design': ['ui', 'design', 'figma', 'animation'],
      'finance': ['money', 'invoice', 'tax', 'payment'],
      'travel': ['travel', 'hotel', 'ticket', 'trip'],
      'food': ['recipe', 'food', 'cooking'],
    };
    for (final entry in candidates.entries) {
      if (_containsAny(lower, entry.value)) tags.add(entry.key);
    }
    final source = detectSource(titleOrUrl);
    if (source != SourceApp.unknown && source != SourceApp.browser) {
      tags.add(source.name);
    }
    return tags.take(4).toList();
  }

  static String typeLabel(VaultItemType type) {
    return switch (type) {
      VaultItemType.instagram => 'Instagram Post/Reel',
      VaultItemType.linkedin => 'LinkedIn Post',
      VaultItemType.youtube => 'Video',
      VaultItemType.pdf => 'PDF',
      VaultItemType.image => 'Image',
      VaultItemType.video => 'Video',
      VaultItemType.note => 'Note',
      VaultItemType.text => 'Text',
      VaultItemType.document => 'Document',
      VaultItemType.voice => 'Voice',
      VaultItemType.screenshot => 'Screenshot',
      VaultItemType.link => 'Link',
    };
  }

  static bool _isLinkType(VaultItemType type) =>
      type == VaultItemType.link ||
      type == VaultItemType.instagram ||
      type == VaultItemType.linkedin ||
      type == VaultItemType.youtube;

  static String _generateTitle(
    String raw,
    String? url,
    SourceApp source,
    VaultItemType type,
  ) {
    if (source == SourceApp.instagram) return 'Instagram post or reel';
    if (source == SourceApp.linkedin) return 'LinkedIn post';
    if (source == SourceApp.youtube) return 'YouTube video';
    if (type == VaultItemType.pdf || type == VaultItemType.image || type == VaultItemType.video) {
      return raw.split(RegExp(r'[\\/]')).last;
    }
    if (url != null) {
      final host = Uri.tryParse(url)?.host.replaceFirst('www.', '');
      return host == null || host.isEmpty ? 'Website link' : host;
    }
    if (raw.isEmpty) return 'Quick capture';
    return raw.length > 48 ? '${raw.substring(0, 48)}...' : raw;
  }

  static String _shortDescription(String raw) {
    if (raw.length <= 140) return raw;
    return '${raw.substring(0, 140)}...';
  }

  static bool _containsAny(String input, List<String> words) => words.any(input.contains);

  static bool _endsWithAny(String input, List<String> suffixes) =>
      suffixes.any(input.endsWith);

  static String? _localCover(String? filePath, String? typeHint) {
    if (filePath == null || typeHint != 'image') return null;
    return filePath;
  }
}
