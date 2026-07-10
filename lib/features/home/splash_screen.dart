import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../capture/capture_provider.dart';
import '../settings/settings_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      if (context.read<CaptureProvider>().hasShareLaunchInProgress) return;
      final settings = context.read<SettingsProvider>();
      Navigator.pushNamedAndRemoveUntil(
        context,
        settings.hasCompletedOnboarding ? AppRoutes.shell : AppRoutes.onboarding,
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 18),
            Text('Vaultly', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Save anything. Find everything.'),
          ],
        ),
      ),
    );
  }
}
