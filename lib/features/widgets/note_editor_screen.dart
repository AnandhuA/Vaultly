import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/vault_item.dart';
import '../../data/repositories/vault_item_repository.dart';
import '../collections/collection_provider.dart';
import '../home/home_provider.dart';
import '../search/search_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.item});

  final VaultItem? item;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final title = TextEditingController();
  final note = TextEditingController();
  String? collectionId;

  @override
  void initState() {
    super.initState();
    title.text = widget.item?.title ?? '';
    note.text = widget.item?.userNote ?? '';
    collectionId = widget.item?.collectionId;
  }

  @override
  Widget build(BuildContext context) {
    final collections = context.watch<CollectionProvider>().collections;
    return Scaffold(
      appBar: AppBar(title: Text(widget.item == null ? 'New Note' : 'Edit Item')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: collectionId,
            decoration: const InputDecoration(labelText: 'Collection'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Smart Inbox')),
              ...collections.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
            ],
            onChanged: (value) => setState(() => collectionId = value),
          ),
          const SizedBox(height: 12),
          TextField(controller: note, minLines: 10, maxLines: 20, decoration: const InputDecoration(labelText: 'Note')),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: FilledButton(onPressed: _save, child: const Text('Save note')),
      ),
    );
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final item = widget.item?.copyWith(
          title: title.text,
          userNote: note.text,
          description: note.text,
          collectionId: collectionId,
          isReadLater: collectionId == null,
          needsReview: collectionId == null,
        ) ??
        VaultItem(
          id: const Uuid().v4(),
          title: title.text.trim().isEmpty ? 'Untitled note' : title.text.trim(),
          description: note.text,
          sourceApp: 'Note',
          itemType: VaultItemType.note,
          collectionId: collectionId,
          userNote: note.text,
          createdAt: now,
          updatedAt: now,
          isReadLater: collectionId == null,
          needsReview: collectionId == null,
          confidence: collectionId == null ? 0.5 : 1,
        );
    await context.read<VaultItemRepository>().save(item);
    if (mounted) {
      context.read<HomeProvider>().load();
      context.read<SearchProvider>().load();
      Navigator.pop(context);
    }
  }
}
