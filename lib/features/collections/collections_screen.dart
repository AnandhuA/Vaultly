import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/widgets/empty_state.dart';
import '../collections/collection_provider.dart';
import '../home/home_provider.dart';
import '../widgets/collection_card.dart';

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final collections = home.collections;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Collections', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
                IconButton(
                  tooltip: 'Create collection',
                  onPressed: () => _create(context),
                  icon: const Icon(Icons.create_new_folder_outlined),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: collections.isEmpty
                  ? EmptyState(title: 'Create your first collection', subtitle: 'Collections keep your saves calm and easy to return to.', actionLabel: 'Create Collection', onAction: () => _create(context))
                  : GridView.count(
                      crossAxisCount: MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
                      childAspectRatio: 1.08,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        for (final collection in collections)
                          CollectionCard(
                            collection: collection,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.collectionDetail, arguments: collection.id),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create collection'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Collection name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Create')),
        ],
      ),
    );
    if (!context.mounted || (name ?? '').trim().isEmpty) return;
    final collectionProvider = context.read<CollectionProvider>();
    final homeProvider = context.read<HomeProvider>();
    {
      await collectionProvider.create(name!.trim());
      homeProvider.load();
    }
  }
}
