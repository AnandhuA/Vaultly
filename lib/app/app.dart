import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/settings/settings_provider.dart';
import '../core/services/app_navigator.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

class VaultlyApp extends StatelessWidget {
  const VaultlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.key,
      title: 'Vaultly',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: settings.hasCompletedOnboarding
          ? AppRoutes.shell
          : AppRoutes.splash,
    );
  }
}
