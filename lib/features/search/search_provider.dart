import 'package:flutter/foundation.dart';

import '../../data/models/vault_collection.dart';
import '../../data/models/vault_item.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/vault_item_repository.dart';

class SearchProvider extends ChangeNotifier {
  SearchProvider(this._items, this._collections);

  final VaultItemRepository _items;
  final CollectionRepository _collections;
  List<VaultItem> allItems = [];
  List<VaultCollection> collections = [];
  String query = '';
  String filter = 'All';

  static const filters = [
    'All',
    'Links',
    'Videos',
    'PDFs',
    'Notes',
    'Images',
    'Documents',
    'Instagram',
    'LinkedIn',
    'YouTube',
  ];

  void load() {
    allItems = _items.all();
    collections = _collections.all();
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setFilter(String value) {
    filter = value;
    notifyListeners();
  }

  List<VaultItem> get results {
    final q = query.trim().toLowerCase();
    return allItems.where((item) {
      final collectionName = collections
              .where((collection) => collection.id == item.collectionId)
              .firstOrNull
              ?.name ??
          '';
      final haystack = [
        item.title,
        item.description,
        item.originalUrl ?? '',
        item.userNote,
        item.sourceApp,
        item.itemType.name,
        collectionName,
        ...item.tags,
      ].join(' ').toLowerCase();
      return (q.isEmpty || haystack.contains(q)) && _matchesFilter(item);
    }).toList();
  }

  bool _matchesFilter(VaultItem item) {
    return switch (filter) {
      'Links' => item.itemType == VaultItemType.link,
      'Videos' => item.itemType == VaultItemType.youtube,
      'PDFs' => item.itemType == VaultItemType.pdf,
      'Notes' => item.itemType == VaultItemType.note || item.itemType == VaultItemType.text,
      'Images' => item.itemType == VaultItemType.image || item.itemType == VaultItemType.screenshot,
      'Documents' => item.itemType == VaultItemType.document,
      'Instagram' => item.itemType == VaultItemType.instagram,
      'LinkedIn' => item.itemType == VaultItemType.linkedin,
      'YouTube' => item.itemType == VaultItemType.youtube,
      _ => true,
    };
  }
}
