import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../core/widgets/cover_image.dart';
import '../../data/models/vault_item.dart';
import '../../data/repositories/vault_item_repository.dart';
import '../collections/collection_provider.dart';
import '../home/home_provider.dart';
import '../search/search_provider.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.item});

  final VaultItem item;

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionProvider>().findById(item.collectionId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved item'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.noteEditor, arguments: item),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () async {
              await context.read<VaultItemRepository>().delete(item.id);
              if (context.mounted) {
                context.read<HomeProvider>().load();
                context.read<SearchProvider>().load();
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CoverImage(
            image: item.thumbnailPath,
            itemType: item.itemType,
            width: double.infinity,
            height: 190,
            borderRadius: 24,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.sourceApp, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text(item.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  if (item.userNote.isNotEmpty) Text(item.userNote),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SelectableText(item.description),
                  ],
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (collection != null) Chip(label: Text(collection.name)),
                    ...item.tags.map((tag) => Chip(label: Text('#$tag'))),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _open(context),
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(item.originalUrl == null ? 'Open viewer' : 'Open link'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<VaultItemRepository>().save(item.copyWith(isFavorite: !item.isFavorite));
              if (context.mounted) {
                context.read<HomeProvider>().load();
                context.read<SearchProvider>().load();
                Navigator.pop(context);
              }
            },
            icon: Icon(item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded),
            label: Text(item.isFavorite ? 'Remove favorite' : 'Add favorite'),
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final url = item.originalUrl;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(item.itemType == VaultItemType.pdf ? 'PDF viewer placeholder' : 'Viewer placeholder')),
      );
      return;
    }
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }
}
