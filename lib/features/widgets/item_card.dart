import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/widgets/cover_image.dart';
import '../../data/models/vault_collection.dart';
import '../../data/models/vault_item.dart';
import '../../data/repositories/vault_item_repository.dart';
import '../home/home_provider.dart';
import '../search/search_provider.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    this.collection,
    this.compact = false,
  });

  final VaultItem item;
  final VaultCollection? collection;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.pushNamed(context, AppRoutes.itemDetail, arguments: item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoverImage(
                image: item.thumbnailPath,
                itemType: item.itemType,
                width: compact ? 52 : 64,
                height: compact ? 52 : 64,
                borderRadius: 16,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          tooltip: item.isFavorite ? 'Unfavorite' : 'Favorite',
                          onPressed: () async {
                            await context.read<VaultItemRepository>().save(
                                  item.copyWith(isFavorite: !item.isFavorite),
                                );
                            if (context.mounted) {
                              context.read<HomeProvider>().load();
                              context.read<SearchProvider>().load();
                            }
                          },
                          icon: Icon(
                            item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                            color: item.isFavorite ? Colors.amber : null,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      item.userNote.isEmpty ? item.description : item.userNote,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Pill(text: item.sourceApp),
                        if (collection != null) _Pill(text: collection!.name),
                        ...item.tags.take(3).map((tag) => _Pill(text: '#$tag')),
                        _Pill(text: DateFormat.MMMd().format(item.createdAt)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
