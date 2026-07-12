import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/vault_item.dart';

class VaultItemRepository {
  static const _boxName = 'vault_items';
  VaultItemRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  late Box _box;
  String? _userId;
  List<VaultItem> _cloudItems = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cloudSubscription;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  bool get isUsingCloud => _userId != null;
  Stream<void> get changes => _changes.stream;

  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
  }

  Future<void> useUser(String? userId) async {
    if (userId == null) {
      await _cloudSubscription?.cancel();
      _cloudSubscription = null;
      _userId = null;
      _cloudItems = [];
      _changes.add(null);
      return;
    }
    await _cloudSubscription?.cancel();
    _userId = userId;
    try {
      await _loadCloudItems();
      if (_box.isNotEmpty) {
        await _migrateLocalItemsToCloud();
        await _loadCloudItems();
      }
      _listenToCloudItems();
      _changes.add(null);
    } on FirebaseException {
      await _cloudSubscription?.cancel();
      _cloudSubscription = null;
      _cloudItems = [];
      _changes.add(null);
    }
  }

  List<VaultItem> all() {
    if (isUsingCloud) {
      return [..._cloudItems]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return _box.values
        .map((value) => VaultItem.fromMap(Map<dynamic, dynamic>.from(value)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> save(VaultItem item) => saveItem(item);

  Future<void> saveItem(VaultItem item) async {
    if (isUsingCloud) {
      await _itemsRef.doc(item.id).set(item.toMap());
      _upsertCloudItem(item);
      _changes.add(null);
      return;
    }
    await _box.put(item.id, item.toMap());
    _changes.add(null);
  }

  Future<void> updateItem(VaultItem item) => saveItem(item);

  Future<void> delete(String id) async {
    if (isUsingCloud) {
      await _itemsRef.doc(id).delete();
      _cloudItems.removeWhere((item) => item.id == id);
      _changes.add(null);
      return;
    }
    await _box.delete(id);
    _changes.add(null);
  }

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

  Future<void> clear() async {
    if (isUsingCloud) {
      final snapshot = await _itemsRef.get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      _cloudItems = [];
      _changes.add(null);
      return;
    }
    await _box.clear();
    _changes.add(null);
  }

  String exportJson() => jsonEncode(all().map((item) => item.toMap()).toList());

  CollectionReference<Map<String, dynamic>> get _itemsRef {
    return _firestore.collection('users').doc(_userId).collection('vault_items');
  }

  Future<void> _loadCloudItems() async {
    final snapshot = await _itemsRef.get();
    _cloudItems = snapshot.docs.map((doc) => VaultItem.fromMap(doc.data())).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _listenToCloudItems() {
    _cloudSubscription = _itemsRef.snapshots().listen(
      (snapshot) {
        _cloudItems = snapshot.docs
            .map((doc) => VaultItem.fromMap(doc.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _changes.add(null);
      },
      onError: (_) {
        _cloudItems = [];
        _changes.add(null);
      },
    );
  }

  Future<void> _migrateLocalItemsToCloud() async {
    final localItems = _box.values
        .map((value) => VaultItem.fromMap(Map<dynamic, dynamic>.from(value)))
        .toList();
    if (localItems.isEmpty) return;
    final batch = _firestore.batch();
    for (final item in localItems) {
      batch.set(_itemsRef.doc(item.id), item.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  void _upsertCloudItem(VaultItem item) {
    final index = _cloudItems.indexWhere((current) => current.id == item.id);
    if (index == -1) {
      _cloudItems.insert(0, item);
    } else {
      _cloudItems[index] = item;
    }
    _cloudItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> dispose() async {
    await _cloudSubscription?.cancel();
    await _changes.close();
  }
}
