import 'package:flutter/material.dart';

import '../data/models/vault_item.dart';
import '../features/capture/save_preview_screen.dart';
import '../features/collections/collection_detail_screen.dart';
import '../features/home/app_shell.dart';
import '../features/home/splash_screen.dart';
import '../features/inbox/smart_inbox_screen.dart';
import '../features/onboarding/first_collection_setup_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/widgets/item_detail_screen.dart';
import '../features/widgets/note_editor_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const firstCollection = '/first-collection';
  static const shell = '/home';
  static const capture = '/capture';
  static const collectionDetail = '/collection';
  static const itemDetail = '/item';
  static const noteEditor = '/note';
  static const smartInbox = '/smart-inbox';
  static const profile = '/profile';
  static const settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    Widget page;
    switch (routeSettings.name) {
      case splash:
        page = const SplashScreen();
      case onboarding:
        page = const OnboardingScreen();
      case firstCollection:
        page = const FirstCollectionSetupScreen();
      case shell:
        page = AppShell(initialIndex: routeSettings.arguments as int? ?? 0);
      case capture:
        page = SavePreviewScreen(seed: routeSettings.arguments as CaptureSeed?);
      case collectionDetail:
        page = CollectionDetailScreen(
          collectionId: routeSettings.arguments! as String,
        );
      case itemDetail:
        page = ItemDetailScreen(item: routeSettings.arguments! as VaultItem);
      case noteEditor:
        page = NoteEditorScreen(item: routeSettings.arguments as VaultItem?);
      case smartInbox:
        page = const SmartInboxScreen();
      case profile:
        page = const ProfileScreen();
      case settings:
        page = const SettingsScreen();
      default:
        page = const AppShell();
    }
    return MaterialPageRoute(builder: (_) => page, settings: routeSettings);
  }
}

class CaptureSeed {
  const CaptureSeed({this.text, this.filePath, this.typeHint});

  final String? text;
  final String? filePath;
  final String? typeHint;
}
