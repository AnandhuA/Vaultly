import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/vault_collection.dart';
import '../../data/models/vault_item.dart';
import '../capture/capture_provider.dart';
import '../home/home_provider.dart';
import '../widgets/collection_card.dart';
import '../widgets/item_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onSearchTap});

  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    if (home.items.isEmpty) {
      return SafeArea(
        child: EmptyState(
          title: 'Your vault is empty',
          subtitle: 'Start by sharing a link from Instagram, YouTube, LinkedIn or Chrome.',
          actionLabel: 'Add first item',
          onAction: () => Navigator.pushNamed(context, AppRoutes.capture),
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => home.load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
          children: [
            _HomeHeader(
              inboxCount: home.smartInbox.length,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(18),
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: 'Search notes, links, videos, PDFs...',
                    suffixIcon: Icon(
                      Icons.tune_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (home.smartInbox.isNotEmpty) ...[
              _ReviewQueueCard(count: home.smartInbox.length),
              const SizedBox(height: 20),
            ],
            _Section(title: 'Quick Save', child: _QuickSave()),
            if (kDebugMode && context.watch<CaptureProvider>().lastReceivedSeed != null)
              _LastShareDebug(seed: context.watch<CaptureProvider>().lastReceivedSeed!),
            if (home.smartInbox.isEmpty)
              const _Section(
                title: 'Smart Inbox',
                child: _InboxSummary(count: 0),
              ),
            _HorizontalItems(title: 'Continue', items: home.continueItems, collections: home.collections),
            _HorizontalItems(title: 'Recently Saved', items: home.recent, collections: home.collections),
            _Section(
              title: 'Collections',
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.sizeOf(context).width > 680 ? 3 : 2,
                childAspectRatio: 1.35,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  for (final collection in home.collections.take(6))
                    CollectionCard(
                      collection: collection,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.collectionDetail, arguments: collection.id),
                    ),
                ],
              ),
            ),
            if (home.todaysFocus.isNotEmpty)
              _HorizontalItems(title: "Today's Focus", items: home.todaysFocus, collections: home.collections),
          ],
        ),
      ),
    );
  }
}

class _LastShareDebug extends StatelessWidget {
  const _LastShareDebug({required this.seed});

  final CaptureSeed seed;

  @override
  Widget build(BuildContext context) {
    final text = seed.text ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.bug_report_outlined),
          title: const Text('Last shared payload'),
          subtitle: Text(
            text.isEmpty ? 'No text received' : text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: text.isEmpty
              ? null
              : () => Navigator.pushNamed(context, AppRoutes.capture, arguments: seed),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
              ?action,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.inboxCount,
  });

  final int inboxCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning, Anandhu',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Save anything. Find everything.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.lock_outline_rounded, color: Colors.white),
              ),
            ],
          ),
          if (inboxCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$inboxCount items need review',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickSave extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = const [
      ('Link', Icons.link_rounded, null),
      ('YouTube', Icons.play_circle_outline_rounded, 'youtube'),
      ('Note', Icons.notes_rounded, 'note'),
      ('PDF', Icons.picture_as_pdf_outlined, 'pdf'),
      ('Image', Icons.image_outlined, 'image'),
      ('Clipboard', Icons.content_paste_rounded, 'text'),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final action = actions[index];
          return ActionChip(
            avatar: Icon(action.$2, size: 18),
            label: Text(action.$1),
            onPressed: () {
              if (action.$3 == 'note') {
                Navigator.pushNamed(context, AppRoutes.noteEditor);
                return;
              }
              Navigator.pushNamed(
                context,
                AppRoutes.capture,
                arguments: CaptureSeed(typeHint: action.$3),
              );
            },
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

class _InboxSummary extends StatelessWidget {
  const _InboxSummary({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.inbox_outlined, color: Theme.of(context).colorScheme.primary),
        title: Text(count == 0 ? 'Everything organized' : '$count items need review'),
        subtitle: const Text('Review uncategorized saves when you have a minute.'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.pushNamed(context, AppRoutes.smartInbox),
      ),
    );
  }
}

class _ReviewQueueCard extends StatelessWidget {
  const _ReviewQueueCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.smartInbox),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.rule_folder_outlined, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review $count ${count == 1 ? 'item' : 'items'}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Swipe, select, and organize your newest saves.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.smartInbox),
                child: const Text('Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HorizontalItems extends StatelessWidget {
  const _HorizontalItems({required this.title, required this.items, required this.collections});

  final String title;
  final List<VaultItem> items;
  final List<VaultCollection> collections;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: title,
      child: Column(
        children: [
          for (final item in items)
            ItemCard(
              item: item,
              collection: collections.where((c) => c.id == item.collectionId).firstOrNull,
              compact: true,
            ),
        ],
      ),
    );
  }
}
