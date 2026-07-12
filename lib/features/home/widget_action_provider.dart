import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
        _openClipboardLink();
        return;
      case 'note':
        AppNavigator.openRoute(AppRoutes.noteEditor);
        return;
      case 'search':
        AppNavigator.openShell(initialIndex: 3);
        return;
    }
  }

  Future<void> _openClipboardLink() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    AppNavigator.openCapture(
      CaptureSeed(text: data?.text ?? '', typeHint: 'link'),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
