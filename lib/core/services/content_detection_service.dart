import '../../data/models/source_app.dart';
import '../../data/models/vault_item.dart';
import '../utils/content_parser.dart';

class ContentDetectionResult {
  const ContentDetectionResult({
    required this.sourceApp,
    required this.itemType,
    required this.title,
    required this.suggestedCollection,
  });

  final String sourceApp;
  final VaultItemType itemType;
  final String title;
  final String? suggestedCollection;
}

class ContentDetectionService {
  static ContentDetectionResult detect(String input, {String? typeHint}) {
    final parsed = ContentParser.parseSharedText(input, typeHint: typeHint);
    return ContentDetectionResult(
      sourceApp: parsed.source.label,
      itemType: parsed.itemType,
      title: parsed.title,
      suggestedCollection: parsed.suggestedCollection,
    );
  }

  static String? suggestCollection(String input) => ContentParser.suggestCollection(input);
}
