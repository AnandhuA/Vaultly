import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
import '../collections/collection_provider.dart';
import '../search/search_provider.dart';
import '../widgets/item_card.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final collections = context.watch<CollectionProvider>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              autofocus: false,
              onChanged: search.setQuery,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search anything you saved'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: SearchProvider.filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = SearchProvider.filters[index];
                  return ChoiceChip(
                    selected: search.filter == filter,
                    label: Text(filter),
                    onSelected: (_) => search.setFilter(filter),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: search.results.isEmpty
                  ? const EmptyState(title: 'Search anything you saved', subtitle: 'Titles, notes, URLs, tags, source apps and collections are searchable.')
                  : ListView(
                      children: [
                        for (final item in search.results)
                          ItemCard(item: item, collection: collections.findById(item.collectionId)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
