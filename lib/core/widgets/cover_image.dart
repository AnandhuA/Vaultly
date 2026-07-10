import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/vault_item.dart';
import '../utils/icon_mapper.dart';

class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.image,
    required this.itemType,
    this.width,
    this.height,
    this.borderRadius = 16,
  });

  final String? image;
  final VaultItemType itemType;
  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width,
        height: height,
        child: _buildImage(context),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final value = image;
    if (value == null || value.trim().isEmpty) return _fallback(context);
    if (value.startsWith('http')) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          final fallbackUrl = _youtubeFallback(value);
          if (fallbackUrl != null) {
            return Image.network(
              fallbackUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(context),
            );
          }
          return _fallback(context);
        },
      );
    }
    final filePath = value.startsWith('file://') ? Uri.parse(value).toFilePath() : value;
    if (File(filePath).existsSync()) {
      return Image.file(
        File(filePath),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(context),
      );
    }
    return _fallback(context);
  }

  String? _youtubeFallback(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.host.contains('img.youtube.com')) return null;
    if (!uri.path.contains('/maxresdefault.jpg')) return null;
    return value.replaceFirst('/maxresdefault.jpg', '/hqdefault.jpg');
  }

  Widget _fallback(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(
        IconMapper.item(itemType),
        color: theme.colorScheme.primary,
        size: (height ?? 48) > 100 ? 44 : 24,
      ),
    );
  }
}
