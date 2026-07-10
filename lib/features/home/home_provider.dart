import 'package:flutter/foundation.dart';

import '../../data/models/vault_collection.dart';
import '../../data/models/vault_item.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/vault_item_repository.dart';

class HomeProvider extends ChangeNotifier {
  HomeProvider(this._items, this._collections);

  final VaultItemRepository _items;
  final CollectionRepository _collections;

  List<VaultItem> items = [];
  List<VaultCollection> collections = [];

  void load() {
    items = _items.all().where((item) => !item.isArchived).toList();
    final counts = <String, int>{};
    for (final item in items) {
      if (item.collectionId != null) {
        counts[item.collectionId!] = (counts[item.collectionId!] ?? 0) + 1;
      }
    }
    collections = _collections
        .all()
        .map((c) => c.copyWith(itemCount: counts[c.id] ?? 0))
        .toList();
    notifyListeners();
  }

  List<VaultItem> get smartInbox =>
      items.where((item) => item.needsReview || item.collectionId == null).toList();
  List<VaultItem> get recent => items.take(8).toList();
  List<VaultItem> get continueItems => items.where((item) => item.isReadLater).take(5).toList();
  List<VaultItem> get todaysFocus =>
      items.where((item) => item.reminderDate != null).take(5).toList();
}
