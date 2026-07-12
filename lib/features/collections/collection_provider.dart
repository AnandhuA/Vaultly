import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/vault_collection.dart';
import '../../data/repositories/collection_repository.dart';

class CollectionProvider extends ChangeNotifier {
  CollectionProvider(this._repository);

  final CollectionRepository _repository;
  StreamSubscription<void>? _subscription;
  List<VaultCollection> collections = [];

  void listen() {
    _subscription ??= _repository.changes.listen((_) => load());
  }

  void load() {
    collections = _repository.all();
    notifyListeners();
  }

  Future<VaultCollection> create(String name) async {
    final collection = await _repository.create(name);
    load();
    return collection;
  }

  VaultCollection? findById(String? id) => _repository.findById(id);
  VaultCollection? findByName(String name) => _repository.findByName(name);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
