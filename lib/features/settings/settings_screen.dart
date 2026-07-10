import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/vault_item_repository.dart';
import '../home/home_provider.dart';
import '../search/search_provider.dart';
import '../settings/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            value: settings.darkMode,
            onChanged: settings.toggleDarkMode,
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
          ),
          const Card(child: ListTile(leading: Icon(Icons.fingerprint_rounded), title: Text('Biometric lock'), subtitle: Text('Placeholder for device lock'))),
          const Card(child: ListTile(leading: Icon(Icons.cloud_upload_outlined), title: Text('Backup'), subtitle: Text('Cloud sync is planned for later'))),
          Card(
            child: ListTile(
              leading: const Icon(Icons.ios_share_outlined),
              title: const Text('Export data as JSON'),
              onTap: () async {
                final json = context.read<VaultItemRepository>().exportJson();
                await Clipboard.setData(ClipboardData(text: json));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vault export copied to clipboard')));
                }
              },
            ),
          ),
          const Card(child: ListTile(leading: Icon(Icons.file_upload_outlined), title: Text('Import data'), subtitle: Text('Placeholder'))),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Clear all data'),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear vault?'),
                    content: const Text('This removes saved items from local storage.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  final repository = context.read<VaultItemRepository>();
                  final home = context.read<HomeProvider>();
                  final search = context.read<SearchProvider>();
                  await repository.clear();
                  home.load();
                  search.load();
                }
              },
            ),
          ),
          const Card(child: ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('Privacy'), subtitle: Text('Offline-first. No backend or login in this MVP.'))),
          const Card(child: ListTile(leading: Icon(Icons.info_outline_rounded), title: Text('About'), subtitle: Text('Vaultly 1.0.0'))),
        ],
      ),
    );
  }
}
