import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/vault_item.dart';

class VaultItemRepository {
  static const _boxName = 'vault_items';
  late Box _box;

  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
  }

  List<VaultItem> all() {
    return _box.values
        .map((value) => VaultItem.fromMap(Map<dynamic, dynamic>.from(value)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> save(VaultItem item) => saveItem(item);

  Future<void> saveItem(VaultItem item) => _box.put(item.id, item.toMap());

  Future<void> updateItem(VaultItem item) => saveItem(item);

  Future<void> delete(String id) => _box.delete(id);

  Future<void> deleteItem(String id) => delete(id);

  List<VaultItem> getRecentItems({int limit = 20}) => all().take(limit).toList();

  List<VaultItem> getNeedsReviewItems() =>
      all().where((item) => item.needsReview || item.collectionId == null).toList();

  List<VaultItem> getItemsByCollection(String collectionId) =>
      all().where((item) => item.collectionId == collectionId).toList();

  List<VaultItem> searchItems(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all();
    return all().where((item) {
      final haystack = [
        item.title,
        item.description,
        item.originalUrl ?? '',
        item.sourceApp,
        item.itemType.name,
        item.userNote,
        ...item.tags,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  Future<void> clear() => _box.clear();

  String exportJson() => jsonEncode(all().map((item) => item.toMap()).toList());
}
