import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/vault_item.dart';
import '../collections/collection_provider.dart';
import '../home/home_provider.dart';
import '../widgets/item_card.dart';

class CollectionDetailScreen extends StatefulWidget {
  const CollectionDetailScreen({super.key, required this.collectionId});

  final String collectionId;

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  String filter = 'All';
  final filters = const ['All', 'Links', 'Videos', 'PDFs', 'Notes', 'Images'];

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionProvider>().findById(widget.collectionId);
    final items = context.watch<HomeProvider>().items.where((item) => item.collectionId == widget.collectionId && _matches(item)).toList();
    return Scaffold(
      appBar: AppBar(title: Text(collection?.name ?? 'Collection')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ChoiceChip(
                selected: filter == filters[index],
                label: Text(filters[index]),
                onSelected: (_) => setState(() => filter = filters[index]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final item in items) ItemCard(item: item, collection: collection),
          if (items.isEmpty) const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No items here yet'))),
        ],
      ),
    );
  }

  bool _matches(VaultItem item) {
    return switch (filter) {
      'Links' => item.itemType == VaultItemType.link,
      'Videos' => item.itemType == VaultItemType.youtube,
      'PDFs' => item.itemType == VaultItemType.pdf,
      'Notes' => item.itemType == VaultItemType.note || item.itemType == VaultItemType.text,
      'Images' => item.itemType == VaultItemType.image || item.itemType == VaultItemType.screenshot,
      _ => true,
    };
  }
}
