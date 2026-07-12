import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/settings/settings_provider.dart';
import '../core/services/app_navigator.dart';
import '../features/home/app_shell.dart';
import '../features/home/splash_screen.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

class VaultlyApp extends StatelessWidget {
  const VaultlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.key,
      title: 'Vaultly',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: auth.isInitializing
          ? const _AuthLoadingScreen()
          : auth.isSignedIn || settings.useLocalStorageWithoutLogin
              ? settings.hasCompletedOnboarding
                  ? const AppShell()
                  : const SplashScreen()
              : const LoginScreen(),
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
