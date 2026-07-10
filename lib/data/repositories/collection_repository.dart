import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/vault_collection.dart';

class CollectionRepository {
  static const _boxName = 'collections';
  static const _uuid = Uuid();
  late Box _box;

  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
  }

  List<VaultCollection> all() {
    return _box.values
        .map((value) => VaultCollection.fromMap(Map<dynamic, dynamic>.from(value)))
        .toList()
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return a.name.compareTo(b.name);
      });
  }

  Future<void> ensureDefaultCollections() async {
    if (_box.isNotEmpty) return;
    for (final collection in defaultCollections()) {
      await save(collection);
    }
  }

  Future<void> save(VaultCollection collection) =>
      _box.put(collection.id, collection.toMap());

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
}
