import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/services/home_widget_service.dart';
import 'core/services/shared_intent_service.dart';
import 'data/repositories/collection_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/vault_item_repository.dart';
import 'features/capture/capture_provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/collections/collection_provider.dart';
import 'features/home/home_provider.dart';
import 'features/home/widget_action_provider.dart';
import 'features/inbox/smart_inbox_provider.dart';
import 'features/search/search_provider.dart';
import 'features/settings/settings_provider.dart';
import 'features/shared_intent/shared_intent_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();

  final sharedPreferences = await SharedPreferences.getInstance();
  final vaultItemRepository = VaultItemRepository();
  final collectionRepository = CollectionRepository();
  final settingsRepository = SettingsRepository(sharedPreferences);

  await vaultItemRepository.initialize();
  await collectionRepository.initialize();
  await settingsRepository.initialize();
  await collectionRepository.ensureDefaultCollections();
  await HomeWidgetService().initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: vaultItemRepository),
        Provider.value(value: collectionRepository),
        Provider.value(value: settingsRepository),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            vaultItemRepository,
            collectionRepository,
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(settingsRepository)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => CollectionProvider(collectionRepository)
            ..listen()
            ..load(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              HomeProvider(vaultItemRepository, collectionRepository)
                ..listen()
                ..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => SmartInboxProvider(vaultItemRepository)
            ..listen()
            ..load(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              SearchProvider(vaultItemRepository, collectionRepository)
                ..listen()
                ..load(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              CaptureProvider(vaultItemRepository, collectionRepository)
                ..initialize(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => SharedIntentProvider(
            SharedIntentService(),
            context.read<CaptureProvider>(),
          )..listen(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => WidgetActionProvider(HomeWidgetService())..listen(),
        ),
      ],
      child: const VaultlyApp(),
    ),
  );
}
