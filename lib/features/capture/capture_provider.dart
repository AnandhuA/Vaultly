import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../app/routes.dart';
import '../../core/utils/content_parser.dart';
import '../../data/models/vault_item.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/vault_item_repository.dart';

class CaptureProvider extends ChangeNotifier {
  CaptureProvider(this._items, this._collections);

  final VaultItemRepository _items;
  final CollectionRepository _collections;
  static const _uuid = Uuid();
  CaptureSeed? incomingSeed;
  CaptureSeed? lastReceivedSeed;
  bool hasShareLaunchInProgress = false;

  void initialize() {}

  Future<VaultItem> save({
    required String title,
    required String rawContent,
    required String sourceApp,
    required VaultItemType itemType,
    String? collectionId,
    required List<String> tags,
    required String note,
    DateTime? reminderDate,
    String? localFilePath,
    String? thumbnailPath,
    bool? needsReview,
    double confidence = 1,
  }) async {
    final now = DateTime.now();
    final isLink = [
      VaultItemType.link,
      VaultItemType.instagram,
      VaultItemType.linkedin,
      VaultItemType.youtube,
    ].contains(itemType);
    final item = VaultItem(
      id: _uuid.v4(),
      title: title.trim().isEmpty ? 'Saved item' : title.trim(),
      description: rawContent,
      originalUrl: isLink ? rawContent.trim() : null,
      sourceApp: sourceApp,
      itemType: itemType,
      collectionId: collectionId,
      tags: tags,
      userNote: note,
      localFilePath: localFilePath,
      thumbnailPath: thumbnailPath,
      createdAt: now,
      updatedAt: now,
      reminderDate: reminderDate,
      isReadLater: collectionId == null,
      needsReview: needsReview ?? collectionId == null || confidence < 0.72,
      confidence: confidence,
    );
    await _items.saveItem(item);
    notifyListeners();
    return item;
  }

  ParsedContent parse(String input, {String? filePath, String? typeHint}) =>
      ContentParser.parseSharedText(input, filePath: filePath, typeHint: typeHint);

  String? suggestedCollectionId(String input) {
    final name = ContentParser.suggestCollection(input);
    return name == null ? null : _collections.findByName(name)?.id;
  }

  void receive(CaptureSeed seed) {
    incomingSeed = seed;
    lastReceivedSeed = seed;
    hasShareLaunchInProgress = true;
    notifyListeners();
  }

  void clearIncoming() {
    incomingSeed = null;
    notifyListeners();
  }

  void completeShareLaunch() {
    incomingSeed = null;
    hasShareLaunchInProgress = false;
    notifyListeners();
  }
}
