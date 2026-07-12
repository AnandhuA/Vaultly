import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/vault_collection.dart';

class CollectionRepository {
  static const _boxName = 'collections';
  static const _uuid = Uuid();
  CollectionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  late Box _box;
  String? _userId;
  List<VaultCollection> _cloudCollections = [];
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
      _cloudCollections = [];
      _changes.add(null);
      return;
    }
    await _cloudSubscription?.cancel();
    _userId = userId;
    try {
      await _loadCloudCollections();
      if (_box.isNotEmpty) {
        await _migrateLocalCollectionsToCloud();
        await _loadCloudCollections();
      }
      if (_cloudCollections.isEmpty) {
        await ensureDefaultCollections();
        await _loadCloudCollections();
      }
      _listenToCloudCollections();
      _changes.add(null);
    } on FirebaseException {
      await _cloudSubscription?.cancel();
      _cloudSubscription = null;
      _cloudCollections = [];
      _changes.add(null);
    }
  }

  List<VaultCollection> all() {
    if (isUsingCloud) {
      return _sortCollections([..._cloudCollections]);
    }
    return _box.values
        .map((value) => VaultCollection.fromMap(Map<dynamic, dynamic>.from(value)))
        .toList()
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return a.name.compareTo(b.name);
      });
  }

  Future<void> ensureDefaultCollections() async {
    if (isUsingCloud && _cloudCollections.isNotEmpty) return;
    if (!isUsingCloud && _box.isNotEmpty) return;
    for (final collection in defaultCollections()) {
      await save(collection);
    }
  }

  Future<void> save(VaultCollection collection) async {
    if (isUsingCloud) {
      await _collectionsRef.doc(collection.id).set(collection.toMap());
      _upsertCloudCollection(collection);
      _changes.add(null);
      return;
    }
    await _box.put(collection.id, collection.toMap());
    _changes.add(null);
  }

  Future<VaultCollection> create(String name) async {
    final now = DateTime.now();
    final collection = VaultCollection(
      id: _uuid.v4(),
      name: name,
      icon: _iconForName(name),
      color: _colorForName(name),
      createdAt: now,
      updatedAt: now,
      isPinned: true,
    );
    await save(collection);
    return collection;
  }

  VaultCollection? findById(String? id) {
    if (id == null) return null;
    if (isUsingCloud) {
      return _cloudCollections.where((collection) => collection.id == id).firstOrNull;
    }
    final raw = _box.get(id);
    return raw == null ? null : VaultCollection.fromMap(raw);
  }

  VaultCollection? findByName(String name) {
    return all().where((c) => c.name.toLowerCase() == name.toLowerCase()).firstOrNull;
  }

  static List<VaultCollection> defaultCollections() {
    final now = DateTime.now();
    final names = ['Flutter', 'Career', 'UI Inspiration', 'Finance', 'Travel', 'Recipes'];
    return [
      for (final name in names)
        VaultCollection(
          id: _uuid.v4(),
          name: name,
          icon: _iconForName(name),
          color: _colorForName(name),
          createdAt: now,
          updatedAt: now,
          isPinned: true,
        ),
    ];
  }

  static String _iconForName(String name) {
    final key = name.toLowerCase();
    if (key.contains('flutter')) return 'code';
    if (key.contains('career')) return 'work';
    if (key.contains('ui')) return 'palette';
    if (key.contains('finance')) return 'payments';
    if (key.contains('travel')) return 'flight';
    if (key.contains('recipe')) return 'restaurant';
    return 'folder';
  }

  static int _colorForName(String name) {
    final key = name.toLowerCase();
    if (key.contains('flutter')) return 0xFF2563EB;
    if (key.contains('career')) return 0xFF7C3AED;
    if (key.contains('ui')) return 0xFFEC4899;
    if (key.contains('finance')) return 0xFF16A34A;
    if (key.contains('travel')) return 0xFF0891B2;
    if (key.contains('recipe')) return 0xFFF97316;
    return 0xFF4F46E5;
  }

  CollectionReference<Map<String, dynamic>> get _collectionsRef {
    return _firestore.collection('users').doc(_userId).collection('collections');
  }

  Future<void> _loadCloudCollections() async {
    final snapshot = await _collectionsRef.get();
    _cloudCollections = _sortCollections(
      snapshot.docs.map((doc) => VaultCollection.fromMap(doc.data())).toList(),
    );
  }

  void _listenToCloudCollections() {
    _cloudSubscription = _collectionsRef.snapshots().listen(
      (snapshot) {
        _cloudCollections = _sortCollections(
          snapshot.docs
              .map((doc) => VaultCollection.fromMap(doc.data()))
              .toList(),
        );
        _changes.add(null);
      },
      onError: (_) {
        _cloudCollections = [];
        _changes.add(null);
      },
    );
  }

  Future<void> _migrateLocalCollectionsToCloud() async {
    final localCollections = _box.values
        .map((value) => VaultCollection.fromMap(Map<dynamic, dynamic>.from(value)))
        .toList();
    if (localCollections.isEmpty) return;
    final batch = _firestore.batch();
    for (final collection in localCollections) {
      batch.set(
        _collectionsRef.doc(collection.id),
        collection.toMap(),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  void _upsertCloudCollection(VaultCollection collection) {
    final index = _cloudCollections.indexWhere((current) => current.id == collection.id);
    if (index == -1) {
      _cloudCollections.add(collection);
    } else {
      _cloudCollections[index] = collection;
    }
    _cloudCollections = _sortCollections(_cloudCollections);
  }

  List<VaultCollection> _sortCollections(List<VaultCollection> collections) {
    return collections
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return a.name.compareTo(b.name);
      });
  }

  Future<void> dispose() async {
    await _cloudSubscription?.cancel();
    await _changes.close();
  }
}
