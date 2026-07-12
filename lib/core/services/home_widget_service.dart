import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static const _methodChannel = MethodChannel('vaultly/widget_action');
  static const _eventChannel = EventChannel('vaultly/widget_action_stream');

  Future<void> initialize() async {
    if (!_supportsHomeWidget) return;
    await HomeWidget.setAppGroupId('group.vaultly.quickcapture');
  }

  Future<void> updateWidget() async {
    if (!_supportsHomeWidget) return;
    await HomeWidget.saveWidgetData<String>('title', 'Vaultly');
    await HomeWidget.saveWidgetData<String>('subtitle', 'Save anything');
    await HomeWidget.updateWidget(name: 'VaultlyQuickCaptureWidgetProvider');
  }

  Future<String?> handleWidgetAction(Uri? uri) async {
    return uri?.queryParameters['action'];
  }

  Future<String?> getInitialWidgetAction() async {
    if (!_supportsNativeWidgetActions) return null;
    final action = await _methodChannel.invokeMethod<String>(
      'getInitialWidgetAction',
    );
    if (action == null || action.trim().isEmpty) return null;
    await _methodChannel.invokeMethod<void>('resetInitialWidgetAction');
    return action;
  }

  Stream<String> listenForWidgetActions() {
    if (!_supportsNativeWidgetActions) return const Stream.empty();
    return _eventChannel.receiveBroadcastStream().where((event) {
      return event is String && event.trim().isNotEmpty;
    }).cast<String>();
  }

  bool get _supportsHomeWidget {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _supportsNativeWidgetActions {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }
}
