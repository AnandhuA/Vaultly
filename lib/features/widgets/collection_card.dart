import 'package:flutter/material.dart';

import '../../core/utils/icon_mapper.dart';
import '../../data/models/vault_collection.dart';

class CollectionCard extends StatelessWidget {
  const CollectionCard({super.key, required this.collection, required this.onTap});

  final VaultCollection collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(collection.color);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(IconMapper.collection(collection.icon), color: color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text('${collection.itemCount} items'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
