import 'package:flutter/material.dart';

import '../../app/routes.dart';

class AppNavigator {
  static final key = GlobalKey<NavigatorState>();

  static Future<void> openCapture(CaptureSeed seed) async {
    await openRoute(AppRoutes.capture, arguments: seed, clearStack: true);
  }

  static Future<void> openShell({int initialIndex = 0}) async {
    await openRoute(AppRoutes.shell, arguments: initialIndex, clearStack: true);
  }

  static Future<void> openRoute(
    String routeName, {
    Object? arguments,
    bool clearStack = false,
  }) async {
    for (var attempt = 0; attempt < 80; attempt++) {
      final navigator = key.currentState;
      if (navigator != null) {
        if (clearStack) {
          navigator.pushNamedAndRemoveUntil(
            routeName,
            (route) => false,
            arguments: arguments,
          );
        } else {
          navigator.pushNamed(routeName, arguments: arguments);
        }
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }
}
