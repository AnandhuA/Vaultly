import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/routes.dart';

class SaveBottomSheet extends StatelessWidget {
  const SaveBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Quick save',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Capture now. Organize only if needed.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _Action(
                icon: Icons.content_paste_rounded,
                label: 'Save Clipboard',
                subtitle: 'Use copied text or link',
                emphasized: true,
                onTap: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (context.mounted) {
                    _open(
                      context,
                      CaptureSeed(text: data?.text ?? '', typeHint: 'text'),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              _Action(
                icon: Icons.link_rounded,
                label: 'Paste Link',
                subtitle: 'Add a URL manually',
                onTap: () => _open(context),
              ),
              _Action(
                icon: Icons.note_add_outlined,
                label: 'New Note',
                subtitle: 'Write a quick thought',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.noteEditor);
                },
              ),
              _Action(
                icon: Icons.short_text_rounded,
                label: 'Text',
                subtitle: 'Paste or write text',
                onTap: () =>
                    _open(context, const CaptureSeed(typeHint: 'text')),
              ),
              _Action(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Import PDF',
                subtitle: 'Save a document',
                onTap: () async {
                  final result = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                  );
                  if (context.mounted && result != null) {
                    _open(
                      context,
                      CaptureSeed(
                        text:
                            result.files.single.path ??
                            result.files.single.name,
                        filePath: result.files.single.path,
                        typeHint: 'pdf',
                      ),
                    );
                  }
                },
              ),
              _Action(
                icon: Icons.image_outlined,
                label: 'Add Image',
                subtitle: 'Pick from gallery',
                onTap: () async {
                  final image = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (context.mounted && image != null) {
                    _open(
                      context,
                      CaptureSeed(
                        text: image.path,
                        filePath: image.path,
                        typeHint: 'image',
                      ),
                    );
                  }
                },
              ),
              _Action(
                icon: Icons.photo_camera_outlined,
                label: 'Take Photo',
                subtitle: 'Capture with camera',
                onTap: () async {
                  final image = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                  );
                  if (context.mounted && image != null) {
                    _open(
                      context,
                      CaptureSeed(
                        text: image.path,
                        filePath: image.path,
                        typeHint: 'image',
                      ),
                    );
                  }
                },
              ),
              _Action(
                icon: Icons.mic_none_rounded,
                label: 'Create Voice Note',
                subtitle: 'Save a spoken thought',
                onTap: () => _open(
                  context,
                  const CaptureSeed(text: 'Voice note', typeHint: 'voice'),
                ),
              ),
              _Action(
                icon: Icons.create_new_folder_outlined,
                label: 'Create Collection',
                subtitle: 'Make a new space',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.firstCollection);
                },
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                Text(
                  'Debug samples',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _DebugChip(
                      label: 'Instagram',
                      text: 'https://www.instagram.com/reel/sample',
                    ),
                    _DebugChip(
                      label: 'LinkedIn',
                      text: 'https://www.linkedin.com/posts/sample',
                    ),
                    _DebugChip(
                      label: 'YouTube',
                      text:
                          'https://youtu.be/sample flutter clean architecture',
                    ),
                    _DebugChip(label: 'Website', text: 'https://flutter.dev'),
                    _DebugChip(
                      label: 'Text',
                      text: 'Useful plain text about provider and Flutter UI',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, [CaptureSeed? seed]) {
    Navigator.pop(context);
    Navigator.pushNamed(context, AppRoutes.capture, arguments: seed);
  }
}

class _DebugChip extends StatelessWidget {
  const _DebugChip({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        Navigator.pop(context);
        Navigator.pushNamed(
          context,
          AppRoutes.capture,
          arguments: CaptureSeed(text: text),
        );
      },
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: emphasized ? theme.colorScheme.primary : theme.colorScheme.surface,
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: emphasized
                ? Colors.white.withValues(alpha: 0.18)
                : theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: emphasized ? Colors.white : theme.colorScheme.primary,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: emphasized ? Colors.white : null,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: emphasized ? Colors.white.withValues(alpha: 0.78) : null,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: emphasized ? Colors.white : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
