import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../auth/auth_provider.dart';
import '../collections/collection_provider.dart';
import '../home/home_provider.dart';
import '../inbox/smart_inbox_provider.dart';
import '../search/search_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final auth = context.watch<AuthProvider>();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  _initial(context),
                  style: const TextStyle(color: Colors.white, fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName(context),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(_email(context)),
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
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Private by design'),
              subtitle: Text(
                auth.isSignedIn
                    ? 'Your vault is saved to your Firebase account.'
                    : 'Your vault is stored locally on this device.',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(auth.isSignedIn ? Icons.logout_rounded : Icons.login_rounded),
              title: Text(auth.isSignedIn ? 'Sign out' : 'Sign in to Firebase'),
              onTap: () async {
                if (!auth.isSignedIn) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                  return;
                }
                await auth.signOut();
                if (context.mounted) {
                  context.read<CollectionProvider>().load();
                  context.read<HomeProvider>().load();
                  context.read<SearchProvider>().load();
                  context.read<SmartInboxProvider>().load();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _displayName(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return user?.email?.split('@').first ?? 'Vaultly user';
  }

  String _email(BuildContext context) {
    return context.watch<AuthProvider>().user?.email ?? 'Local mode';
  }

  String _initial(BuildContext context) {
    final value = _displayName(context);
    return value.isEmpty ? 'V' : value.substring(0, 1).toUpperCase();
  }
}
