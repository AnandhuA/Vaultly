import 'package:flutter/foundation.dart';

import '../../data/models/vault_item.dart';
import '../../data/repositories/vault_item_repository.dart';

class SmartInboxProvider extends ChangeNotifier {
  SmartInboxProvider(this._repository);

  final VaultItemRepository _repository;
  List<VaultItem> items = [];

  void load() {
    items = _repository.getNeedsReviewItems();
    notifyListeners();
  }

  Future<void> markDone(
    VaultItem item, {
    String? collectionId,
    String? note,
  }) async {
    await _repository.updateItem(
      item.copyWith(
        collectionId: collectionId,
        userNote: note?.trim().isEmpty ?? true ? item.userNote : note!.trim(),
        needsReview: false,
        isReadLater: false,
      ),
    );
    load();
  }

  Future<void> moveToCollection(VaultItem item, String collectionId) async {
    await _repository.updateItem(
      item.copyWith(
        collectionId: collectionId,
        needsReview: false,
        isReadLater: false,
      ),
    );
    load();
  }

  Future<void> deleteItem(VaultItem item) async {
    await _repository.deleteItem(item.id);
    load();
  }

  Future<void> markDoneMany(Iterable<VaultItem> items) async {
    for (final item in items) {
      await _repository.updateItem(
        item.copyWith(needsReview: false, isReadLater: false),
      );
    }
    load();
  }

  Future<void> moveMany(Iterable<VaultItem> items, String collectionId) async {
    for (final item in items) {
      await _repository.updateItem(
        item.copyWith(
          collectionId: collectionId,
          needsReview: false,
          isReadLater: false,
        ),
      );
    }
    load();
  }

  Future<void> deleteMany(Iterable<VaultItem> items) async {
    for (final item in items) {
      await _repository.deleteItem(item.id);
    }
    load();
  }
}
