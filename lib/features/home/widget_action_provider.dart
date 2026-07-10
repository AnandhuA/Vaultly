import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../app/routes.dart';
import '../../core/services/app_navigator.dart';
import '../../core/services/home_widget_service.dart';

class WidgetActionProvider extends ChangeNotifier {
  WidgetActionProvider(this._service);

  final HomeWidgetService _service;
  StreamSubscription<String>? _subscription;

  Future<void> listen() async {
    await _service.initialize();
    await _service.updateWidget();
    final initialAction = await _service.getInitialWidgetAction();
    if (initialAction != null) _handle(initialAction);
    _subscription = _service.listenForWidgetActions().listen(_handle);
  }

  void _handle(String action) {
    switch (action) {
      case 'clipboard':
        AppNavigator.openCapture(const CaptureSeed(typeHint: 'text'));
        return;
      case 'link':
        AppNavigator.openCapture(const CaptureSeed(typeHint: 'link'));
        return;
      case 'note':
        AppNavigator.openRoute(AppRoutes.noteEditor);
        return;
      case 'search':
        AppNavigator.openShell(initialIndex: 3);
        return;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
