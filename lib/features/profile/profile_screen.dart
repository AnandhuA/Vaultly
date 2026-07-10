import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../home/home_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
        children: [
          Row(
            children: [
              CircleAvatar(radius: 34, backgroundColor: Theme.of(context).colorScheme.primary, child: const Text('A', style: TextStyle(color: Colors.white, fontSize: 28))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Anandhu', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text('${home.items.length} saved items'),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(child: ListTile(leading: const Icon(Icons.star_border_rounded), title: const Text('Favorites'), subtitle: Text('${home.items.where((i) => i.isFavorite).length} items'))),
          Card(child: ListTile(leading: const Icon(Icons.inbox_outlined), title: const Text('Smart Inbox'), subtitle: Text('${home.smartInbox.length} items need collection'), onTap: () => Navigator.pushNamed(context, AppRoutes.smartInbox))),
          Card(child: ListTile(leading: const Icon(Icons.privacy_tip_outlined), title: const Text('Private by design'), subtitle: const Text('Your MVP vault is stored locally on this device.'))),
        ],
      ),
    );
  }
}
