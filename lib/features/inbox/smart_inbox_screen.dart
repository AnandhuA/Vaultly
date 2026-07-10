import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/content_parser.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/widgets/cover_image.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/vault_collection.dart';
import '../../data/models/vault_item.dart';
import '../collections/collection_provider.dart';
import '../home/home_provider.dart';
import '../search/search_provider.dart';
import 'smart_inbox_provider.dart';

class SmartInboxScreen extends StatefulWidget {
  const SmartInboxScreen({super.key});

  @override
  State<SmartInboxScreen> createState() => _SmartInboxScreenState();
}

class _SmartInboxScreenState extends State<SmartInboxScreen> {
  final Set<String> _selectedIds = {};

  bool get _isSelecting => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SmartInboxProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<SmartInboxProvider>();
    final collections = context.watch<CollectionProvider>().collections;
    final selectedItems = inbox.items.where((item) => _selectedIds.contains(item.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelecting ? '${_selectedIds.length} selected' : 'Smart Inbox'),
        leading: _isSelecting
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(_selectedIds.clear),
              )
            : null,
        actions: [
          if (_isSelecting) ...[
            IconButton(
              tooltip: 'Done',
              onPressed: selectedItems.isEmpty ? null : () => _markDoneMany(selectedItems),
              icon: const Icon(Icons.check_rounded),
            ),
            IconButton(
              tooltip: 'Move',
              onPressed: selectedItems.isEmpty
                  ? null
                  : () => _showMoveSheet(items: selectedItems, collections: collections),
              icon: const Icon(Icons.drive_file_move_outline_rounded),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: selectedItems.isEmpty ? null : () => _deleteMany(selectedItems),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ],
      ),
      body: inbox.items.isEmpty
          ? const EmptyState(
              title: 'Everything organized',
              subtitle: 'New unsorted saves will appear here.',
            )
          : Stack(
              children: [
                ListView(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, _isSelecting ? 108 : 24),
                  children: [
                    _InboxHero(count: inbox.items.length),
                    const SizedBox(height: 16),
                    for (final item in inbox.items)
                      _ReviewCard(
                        item: item,
                        collections: collections,
                        selected: _selectedIds.contains(item.id),
                        selecting: _isSelecting,
                        onToggleSelected: () => _toggleSelected(item.id),
                        onDone: () => _markDone(item),
                        onMove: () => _showMoveSheet(item: item, collections: collections),
                        onDelete: () => _deleteItem(item),
                        onCollectionSelected: (collection) => _moveItem(item, collection.id),
                      ),
                  ],
                ),
                if (_isSelecting)
                  _BulkActionBar(
                    count: _selectedIds.length,
                    onDone: () => _markDoneMany(selectedItems),
                    onMove: () => _showMoveSheet(items: selectedItems, collections: collections),
                    onDelete: () => _deleteMany(selectedItems),
                  ),
              ],
            ),
    );
  }

  void _toggleSelected(String id) {
    setState(() {
      if (!_selectedIds.add(id)) _selectedIds.remove(id);
    });
  }

  Future<void> _markDone(VaultItem item) async {
    await context.read<SmartInboxProvider>().markDone(item);
    if (!mounted) return;
    _afterInboxChange();
    _showSnack('Marked done');
  }

  Future<void> _moveItem(VaultItem item, String collectionId) async {
    await context.read<SmartInboxProvider>().moveToCollection(item, collectionId);
    if (!mounted) return;
    _afterInboxChange();
    _showSnack('Moved to collection');
  }

  Future<void> _deleteItem(VaultItem item) async {
    await context.read<SmartInboxProvider>().deleteItem(item);
    if (!mounted) return;
    _selectedIds.remove(item.id);
    _afterInboxChange();
    _showSnack('Deleted item');
  }

  Future<void> _markDoneMany(List<VaultItem> items) async {
    await context.read<SmartInboxProvider>().markDoneMany(items);
    if (!mounted) return;
    setState(_selectedIds.clear);
    _afterInboxChange();
    _showSnack('Marked ${items.length} done');
  }

  Future<void> _moveMany(List<VaultItem> items, String collectionId) async {
    await context.read<SmartInboxProvider>().moveMany(items, collectionId);
    if (!mounted) return;
    setState(_selectedIds.clear);
    _afterInboxChange();
    _showSnack('Moved ${items.length} items');
  }

  Future<void> _deleteMany(List<VaultItem> items) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete selected items?'),
        content: Text('This will remove ${items.length} items from Vaultly.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await context.read<SmartInboxProvider>().deleteMany(items);
    if (!mounted) return;
    setState(_selectedIds.clear);
    _afterInboxChange();
    _showSnack('Deleted ${items.length} items');
  }

  Future<void> _showMoveSheet({
    VaultItem? item,
    List<VaultItem>? items,
    required List<VaultCollection> collections,
  }) async {
    if (collections.isEmpty) {
      _showSnack('Create a collection first');
      return;
    }
    final collection = await showModalBottomSheet<VaultCollection>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Move to collection',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final collection in collections)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(collection.color).withValues(alpha: 0.14),
                  child: Icon(
                    IconMapper.collection(collection.icon),
                    color: Color(collection.color),
                  ),
                ),
                title: Text(collection.name),
                onTap: () => Navigator.pop(context, collection),
              ),
          ],
        ),
      ),
    );
    if (collection == null) return;
    if (item != null) {
      await _moveItem(item, collection.id);
    } else {
      await _moveMany(items ?? const [], collection.id);
    }
  }

  void _afterInboxChange() {
    context.read<HomeProvider>().load();
    context.read<SearchProvider>().load();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _InboxHero extends StatelessWidget {
  const _InboxHero({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.13),
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
                  'Swipe to finish fast, or long press to organize in bulk.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.item,
    required this.collections,
    required this.selected,
    required this.selecting,
    required this.onToggleSelected,
    required this.onDone,
    required this.onMove,
    required this.onDelete,
    required this.onCollectionSelected,
  });

  final VaultItem item;
  final List<VaultCollection> collections;
  final bool selected;
  final bool selecting;
  final VoidCallback onToggleSelected;
  final VoidCallback onDone;
  final VoidCallback onMove;
  final VoidCallback onDelete;
  final ValueChanged<VaultCollection> onCollectionSelected;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: Colors.green,
        icon: Icons.check_rounded,
        label: 'Done',
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: Theme.of(context).colorScheme.error,
        icon: Icons.delete_outline_rounded,
        label: 'Delete',
      ),
      confirmDismiss: (direction) async {
        if (selecting) {
          onToggleSelected();
          return false;
        }
        if (direction == DismissDirection.startToEnd) {
          onDone();
        } else {
          onDelete();
        }
        return false;
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selecting ? onToggleSelected : onMove,
          onLongPress: onToggleSelected,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selecting) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, right: 12),
                    child: Icon(
                      selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: selected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                ],
                CoverImage(
                  image: item.thumbnailPath,
                  itemType: item.itemType,
                  width: 58,
                  height: 58,
                  borderRadius: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ReviewCardBody(
                    item: item,
                    collections: collections,
                    onCollectionSelected: onCollectionSelected,
                    onMove: onMove,
                    onDone: onDone,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCardBody extends StatelessWidget {
  const _ReviewCardBody({
    required this.item,
    required this.collections,
    required this.onCollectionSelected,
    required this.onMove,
    required this.onDone,
  });

  final VaultItem item;
  final List<VaultCollection> collections;
  final ValueChanged<VaultCollection> onCollectionSelected;
  final VoidCallback onMove;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = _suggestCollections(item, collections);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: 'Move',
              visualDensity: VisualDensity.compact,
              onPressed: onMove,
              icon: const Icon(Icons.drive_file_move_outline_rounded),
            ),
          ],
        ),
        Text(
          [
            item.sourceApp,
            ContentParser.typeLabel(item.itemType),
            DateFormat.MMMd().format(item.createdAt),
          ].join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        if (item.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final collection in suggestions)
              ActionChip(
                avatar: Icon(IconMapper.collection(collection.icon), size: 16),
                label: Text(collection.name),
                onPressed: () => onCollectionSelected(collection),
              ),
            ActionChip(
              avatar: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Done'),
              onPressed: onDone,
            ),
          ],
        ),
      ],
    );
  }

  List<VaultCollection> _suggestCollections(
    VaultItem item,
    List<VaultCollection> collections,
  ) {
    final scored = <({VaultCollection collection, int score})>[];
    final itemText = [
      item.title,
      item.description,
      item.originalUrl ?? '',
      item.sourceApp,
      item.itemType.name,
      item.userNote,
      ...item.tags,
    ].join(' ').toLowerCase();

    for (final collection in collections) {
      var score = 0;
      final name = collection.name.toLowerCase();
      if (itemText.contains(name)) score += 4;
      for (final part in name.split(RegExp(r'\s+'))) {
        if (part.length > 2 && itemText.contains(part)) score += 2;
      }
      if (item.itemType == VaultItemType.youtube && name.contains('flutter')) score += 1;
      if (item.itemType == VaultItemType.linkedin && name.contains('career')) score += 2;
      if (item.tags.any((tag) => name.contains(tag.toLowerCase()))) score += 3;
      if (score > 0) scored.add((collection: collection, score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final suggestions = scored.map((entry) => entry.collection).take(3).toList();
    if (suggestions.isNotEmpty) return suggestions;
    return collections.take(3).toList();
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      alignment: alignment,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: isLeft ? TextDirection.ltr : TextDirection.rtl,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _BulkActionBar extends StatelessWidget {
  const _BulkActionBar({
    required this.count,
    required this.onDone,
    required this.onMove,
    required this.onDelete,
  });

  final int count;
  final VoidCallback onDone;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        elevation: 4,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$count selected',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: 'Done',
                onPressed: onDone,
                icon: const Icon(Icons.check_rounded),
              ),
              IconButton.filledTonal(
                tooltip: 'Move',
                onPressed: onMove,
                icon: const Icon(Icons.drive_file_move_outline_rounded),
              ),
              IconButton.filledTonal(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
