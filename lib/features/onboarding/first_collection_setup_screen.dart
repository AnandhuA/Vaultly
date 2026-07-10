import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../collections/collection_provider.dart';
import '../settings/settings_provider.dart';

class FirstCollectionSetupScreen extends StatefulWidget {
  const FirstCollectionSetupScreen({super.key});

  @override
  State<FirstCollectionSetupScreen> createState() => _FirstCollectionSetupScreenState();
}

class _FirstCollectionSetupScreenState extends State<FirstCollectionSetupScreen> {
  final selected = <String>{'Flutter', 'Career', 'UI Inspiration'};
  final suggestions = ['Flutter', 'Career', 'UI Inspiration', 'Personal', 'Finance', 'Travel'];
  final custom = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [
        TextButton(onPressed: _finish, child: const Text('Skip')),
      ]),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Start with a few collections', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Pick the spaces Vaultly should suggest while you save.'),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final name in suggestions)
                    FilterChip(
                      selected: selected.contains(name),
                      label: Text(name),
                      onSelected: (value) => setState(() {
                        value ? selected.add(name) : selected.remove(name);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: custom,
                decoration: const InputDecoration(hintText: 'Add a custom collection'),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    setState(() => selected.add(value.trim()));
                    custom.clear();
                  }
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _finish, child: const Text('Enter Vaultly')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finish() async {
    final collections = context.read<CollectionProvider>();
    final settings = context.read<SettingsProvider>();
    for (final name in selected) {
      if (collections.findByName(name) == null) {
        await collections.create(name);
      }
    }
    if (mounted) {
      await settings.completeOnboarding();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.shell, (route) => false);
    }
  }
}
