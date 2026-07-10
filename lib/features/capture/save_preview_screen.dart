import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/services/link_preview_service.dart';
import '../../core/utils/content_parser.dart';
import '../../core/widgets/cover_image.dart';
import '../../data/models/vault_collection.dart';
import '../../data/models/source_app.dart';
import '../capture/capture_provider.dart';
import '../collections/collection_provider.dart';
import '../home/home_provider.dart';
import '../inbox/smart_inbox_provider.dart';
import '../search/search_provider.dart';

class SavePreviewScreen extends StatefulWidget {
  const SavePreviewScreen({super.key, this.seed});

  final CaptureSeed? seed;

  @override
  State<SavePreviewScreen> createState() => _SavePreviewScreenState();
}

class _SavePreviewScreenState extends State<SavePreviewScreen> {
  final content = TextEditingController();
  final title = TextEditingController();
  final note = TextEditingController();
  final tags = TextEditingController();
  String? collectionId;
  DateTime? reminderDate;
  bool showDetails = false;
  bool loadingCover = false;
  int _coverRequest = 0;
  String? coverImage;
  late ParsedContent parsed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CaptureProvider>().clearIncoming();
    });
    content.text = widget.seed?.text ?? '';
    _parse(resetTitle: true);
    _loadCover();
    if (content.text.isEmpty && widget.seed?.typeHint == 'text') {
      Clipboard.getData(Clipboard.kTextPlain).then((data) {
        if (!mounted || (data?.text ?? '').isEmpty) return;
        setState(() {
          content.text = data!.text!;
          _parse(resetTitle: true);
          _loadCover();
        });
      });
    }
  }

  void _parse({bool resetTitle = false}) {
    parsed = context.read<CaptureProvider>().parse(
          content.text,
          filePath: widget.seed?.filePath,
          typeHint: widget.seed?.typeHint,
        );
    if (resetTitle || title.text.trim().isEmpty) title.text = parsed.title;
    tags.text = parsed.tags.join(' ');
    if (parsed.coverImageUrl != null) coverImage = parsed.coverImageUrl;
    collectionId = parsed.suggestedCollection == null
        ? null
        : context.read<CollectionProvider>().findByName(parsed.suggestedCollection!)?.id;
  }

  @override
  Widget build(BuildContext context) {
    final collections = context.watch<CollectionProvider>().collections;
    final selectedCollection = context.watch<CollectionProvider>().findById(collectionId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Save to Vaultly'),
        actions: [
          TextButton(
            onPressed: () => setState(() => showDetails = !showDetails),
            child: Text(showDetails ? 'Less' : 'Add details'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          _PreviewCard(parsed: parsed, coverImage: coverImage),
          if (loadingCover) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ] else if (coverImage == null && ContentParser.extractFirstUrl(content.text) != null) ...[
            const SizedBox(height: 8),
            Text(
              'No cover image found. You can still save it.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 14),
          if (selectedCollection != null || parsed.suggestedCollection != null)
            Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(selectedCollection?.name ?? parsed.suggestedCollection!),
                onDeleted: () => setState(() => collectionId = null),
              ),
            )
          else
            const _InboxHint(),
          const SizedBox(height: 14),
          TextField(
            controller: content,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Shared content'),
            onChanged: (_) {
              setState(() => _parse());
              _loadCover();
            },
          ),
          const SizedBox(height: 12),
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
          if (showDetails) ...[
            const SizedBox(height: 12),
            _CollectionChips(
              selectedCollectionId: collectionId,
              collections: collections,
              onSelected: (value) => setState(() => collectionId = value),
              onCreateCustom: _createCustomCollection,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tags,
              decoration: const InputDecoration(labelText: 'Tags', hintText: 'flutter design job'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (picked != null) {
                  setState(() {
                    reminderDate = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
                  });
                }
              },
              icon: const Icon(Icons.notifications_none_rounded),
              label: Text(reminderDate == null ? 'Add reminder' : 'Reminder set'),
            ),
          ] else ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() => showDetails = true),
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Add details'),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: content.text.trim().isEmpty ? null : () => _save(reviewLater: true),
                child: const Text('Save & Review Later'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: content.text.trim().isEmpty ? null : () => _save(reviewLater: false),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save({required bool reviewLater}) async {
    final selectedCollection = context.read<CollectionProvider>().findById(collectionId);
    final item = await context.read<CaptureProvider>().save(
          title: title.text,
          rawContent: content.text,
          sourceApp: parsed.source.label,
          itemType: parsed.itemType,
          collectionId: collectionId,
          tags: tags.text.split(RegExp(r'[\s,#]+')).where((tag) => tag.isNotEmpty).toList(),
          note: note.text,
          reminderDate: reminderDate,
          localFilePath: parsed.localFilePath,
          thumbnailPath: coverImage,
          needsReview: reviewLater || collectionId == null || parsed.confidence < 0.72,
          confidence: parsed.confidence,
        );
    if (!mounted) return;
    context.read<HomeProvider>().load();
    context.read<SmartInboxProvider>().load();
    context.read<SearchProvider>().load();
    context.read<CaptureProvider>().completeShareLaunch();
    final destination = selectedCollection?.name ?? 'Smart Inbox';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved to $destination'),
        action: SnackBarAction(
          label: reviewLater ? 'Review' : 'Open',
          onPressed: () {
            if (reviewLater || item.needsReview) {
              Navigator.pushNamed(context, AppRoutes.smartInbox);
            } else {
              Navigator.pushNamed(context, AppRoutes.itemDetail, arguments: item);
            }
          },
        ),
      ),
    );
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.shell, (route) => false);
  }

  Future<void> _loadCover() async {
    final request = ++_coverRequest;
    final immediate = parsed.coverImageUrl;
    if (immediate != null) {
      setState(() {
        coverImage = immediate;
        loadingCover = false;
      });
      return;
    }

    final url = ContentParser.extractFirstUrl(content.text);
    if (url == null) {
      setState(() {
        coverImage = null;
        loadingCover = false;
      });
      return;
    }

    setState(() => loadingCover = true);
    final cover = await LinkPreviewService().coverFor(url);
    if (!mounted || request != _coverRequest) return;
    setState(() {
      coverImage = cover;
      loadingCover = false;
    });
  }

  Future<void> _createCustomCollection() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Category name'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    final trimmed = name?.trim();
    if (!mounted || trimmed == null || trimmed.isEmpty) return;

    final provider = context.read<CollectionProvider>();
    final existing = provider.findByName(trimmed);
    final collection = existing ?? await provider.create(trimmed);
    if (!mounted) return;
    setState(() => collectionId = collection.id);
  }
}

class _CollectionChips extends StatelessWidget {
  const _CollectionChips({
    required this.selectedCollectionId,
    required this.collections,
    required this.onSelected,
    required this.onCreateCustom,
  });

  final String? selectedCollectionId;
  final List<VaultCollection> collections;
  final ValueChanged<String?> onSelected;
  final VoidCallback onCreateCustom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                selected: selectedCollectionId == null,
                label: const Text('Smart Inbox'),
                avatar: const Icon(Icons.inbox_outlined, size: 18),
                onSelected: (_) => onSelected(null),
              ),
              for (final collection in collections)
                ChoiceChip(
                  selected: selectedCollectionId == collection.id,
                  label: Text(collection.name),
                  onSelected: (_) => onSelected(collection.id),
                ),
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Custom category'),
                onPressed: onCreateCustom,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.parsed, required this.coverImage});

  final ParsedContent parsed;
  final String? coverImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: CoverImage(
              image: coverImage,
              itemType: parsed.itemType,
              width: double.infinity,
              height: double.infinity,
              borderRadius: 0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${parsed.source.label} • ${ContentParser.typeLabel(parsed.itemType)}',
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  parsed.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  parsed.description.isEmpty ? 'Ready to save' : parsed.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _InboxHint extends StatelessWidget {
  const _InboxHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.inbox_outlined, size: 20),
          SizedBox(width: 10),
          Expanded(child: Text('No confident collection yet. Save now to Smart Inbox.')),
        ],
      ),
    );
  }
}
