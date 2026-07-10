import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../data/models/vault_collection.dart';
import '../../data/models/vault_item.dart';
import '../capture/capture_provider.dart';
import '../home/home_provider.dart';
import '../widgets/collection_card.dart';
import '../widgets/item_card.dart';
import 'save_bottom_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onSearchTap});

  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    if (home.items.isEmpty) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
          children: [
            const _EmptyHomeHero(),
            const SizedBox(height: 18),
            _StarterActions(onMore: () => _showSaveSheet(context)),
            const SizedBox(height: 22),
            const _UseCasesCard(),
          ],
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => home.load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
          children: [
            _HomeHeader(inboxCount: home.smartInbox.length),
            const SizedBox(height: 16),
            _MemoryStats(
              itemCount: home.items.length,
              inboxCount: home.smartInbox.length,
              collectionCount: home.collections.length,
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
            _DailyNudgeCard(onMore: () => _showSaveSheet(context)),
            const SizedBox(height: 20),
            if (home.smartInbox.isNotEmpty) ...[
              _ReviewQueueCard(count: home.smartInbox.length),
              const SizedBox(height: 20),
            ],
            _Section(title: 'Quick Save', child: _QuickSave()),
            if (kDebugMode &&
                context.watch<CaptureProvider>().lastReceivedSeed != null)
              _LastShareDebug(
                seed: context.watch<CaptureProvider>().lastReceivedSeed!,
              ),
            if (home.smartInbox.isEmpty)
              const _Section(
                title: 'Smart Inbox',
                child: _InboxSummary(count: 0),
              ),
            _HorizontalItems(
              title: 'Continue',
              items: home.continueItems,
              collections: home.collections,
            ),
            _HorizontalItems(
              title: 'Recently Saved',
              items: home.recent,
              collections: home.collections,
            ),
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
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.collectionDetail,
                        arguments: collection.id,
                      ),
                    ),
                ],
              ),
            ),
            if (home.todaysFocus.isNotEmpty)
              _HorizontalItems(
                title: "Today's Focus",
                items: home.todaysFocus,
                collections: home.collections,
              ),
          ],
        ),
      ),
    );
  }

  void _showSaveSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SaveBottomSheet(),
    );
  }
}

class _EmptyHomeHero extends StatelessWidget {
  const _EmptyHomeHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.bookmark_add_outlined, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Text(
            'Make Vaultly useful in 10 seconds',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save one link, video, note, or screenshot you normally forget. Vaultly will turn it into a searchable memory.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarterActions extends StatelessWidget {
  const _StarterActions({required this.onMore});

  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Start with one save',
      child: Column(
        children: [
          _StarterActionTile(
            icon: Icons.link_rounded,
            title: 'Paste a link',
            subtitle: 'YouTube, Instagram, article, product, anything',
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.capture,
              arguments: const CaptureSeed(typeHint: 'link'),
            ),
          ),
          _StarterActionTile(
            icon: Icons.notes_rounded,
            title: 'Write a note',
            subtitle: 'Idea, task, recommendation, place to remember',
            onTap: () => Navigator.pushNamed(context, AppRoutes.noteEditor),
          ),
          _StarterActionTile(
            icon: Icons.photo_camera_outlined,
            title: 'Take a photo',
            subtitle: 'Capture a receipt, product, book, or screenshot',
            onTap: () async {
              final image = await ImagePicker().pickImage(
                source: ImageSource.camera,
              );
              if (!context.mounted || image == null) return;
              Navigator.pushNamed(
                context,
                AppRoutes.capture,
                arguments: CaptureSeed(
                  text: image.path,
                  filePath: image.path,
                  typeHint: 'image',
                ),
              );
            },
          ),
          _StarterActionTile(
            icon: Icons.mic_none_rounded,
            title: 'Create voice note',
            subtitle: 'Save a quick spoken idea to organize later',
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.capture,
              arguments: const CaptureSeed(
                text: 'Voice note',
                typeHint: 'voice',
              ),
            ),
          ),
          _StarterActionTile(
            icon: Icons.add_rounded,
            title: 'Show all save options',
            subtitle: 'Clipboard, PDF, image, text, collection',
            onTap: onMore,
          ),
        ],
      ),
    );
  }
}

class _StarterActionTile extends StatelessWidget {
  const _StarterActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _UseCasesCard extends StatelessWidget {
  const _UseCasesCard();

  @override
  Widget build(BuildContext context) {
    final ideas = const [
      ('Watch later', 'Save videos you want to actually find again.'),
      ('Shopping', 'Keep product links before you decide.'),
      ('Learning', 'Collect Flutter, design, career, and finance ideas.'),
      ('Life memory', 'Save places, recipes, messages, and screenshots.'),
    ];
    return _Section(
      title: 'What to use it for',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (final idea in ideas)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline_rounded),
                  title: Text(idea.$1),
                  subtitle: Text(idea.$2),
                ),
            ],
          ),
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
              : () => Navigator.pushNamed(
                  context,
                  AppRoutes.capture,
                  arguments: seed,
                ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
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
  const _HomeHeader({required this.inboxCount});

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
                      'Welcome back',
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
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white,
                ),
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

class _MemoryStats extends StatelessWidget {
  const _MemoryStats({
    required this.itemCount,
    required this.inboxCount,
    required this.collectionCount,
  });

  final int itemCount;
  final int inboxCount;
  final int collectionCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '$itemCount',
            label: 'Saved',
            icon: Icons.bookmarks_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '$inboxCount',
            label: 'Review',
            icon: Icons.inbox_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '$collectionCount',
            label: 'Spaces',
            icon: Icons.folder_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(label, style: theme.textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _DailyNudgeCard extends StatelessWidget {
  const _DailyNudgeCard({required this.onMore});

  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.lightbulb_outline_rounded,
                color: theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Save one thing for future you',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'A link, idea, product, recipe, video, or screenshot.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton.filled(
              tooltip: 'Quick save',
              onPressed: onMore,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
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
      ('Photo', Icons.photo_camera_outlined, 'camera'),
      ('Voice', Icons.mic_none_rounded, 'voice'),
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
            onPressed: () async {
              if (action.$3 == 'note') {
                Navigator.pushNamed(context, AppRoutes.noteEditor);
                return;
              }
              if (action.$3 == 'camera') {
                final image = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                );
                if (!context.mounted || image == null) return;
                Navigator.pushNamed(
                  context,
                  AppRoutes.capture,
                  arguments: CaptureSeed(
                    text: image.path,
                    filePath: image.path,
                    typeHint: 'image',
                  ),
                );
                return;
              }
              if (action.$3 == 'voice') {
                Navigator.pushNamed(
                  context,
                  AppRoutes.capture,
                  arguments: const CaptureSeed(
                    text: 'Voice note',
                    typeHint: 'voice',
                  ),
                );
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
        leading: Icon(
          Icons.inbox_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          count == 0 ? 'Everything organized' : '$count items need review',
        ),
        subtitle: const Text(
          'Review uncategorized saves when you have a minute.',
        ),
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
                child: Icon(
                  Icons.rule_folder_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review $count ${count == 1 ? 'item' : 'items'}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
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
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.smartInbox),
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
  const _HorizontalItems({
    required this.title,
    required this.items,
    required this.collections,
  });

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
              collection: collections
                  .where((c) => c.id == item.collectionId)
                  .firstOrNull,
              compact: true,
            ),
        ],
      ),
    );
  }
}
