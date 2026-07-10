import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static const _methodChannel = MethodChannel('vaultly/widget_action');
  static const _eventChannel = EventChannel('vaultly/widget_action_stream');

  Future<void> initialize() async {
    await HomeWidget.setAppGroupId('group.vaultly.quickcapture');
  }

  Future<void> updateWidget() async {
    await HomeWidget.saveWidgetData<String>('title', 'Vaultly');
    await HomeWidget.saveWidgetData<String>('subtitle', 'Save anything');
    await HomeWidget.updateWidget(name: 'VaultlyQuickCaptureWidgetProvider');
  }

  Future<String?> handleWidgetAction(Uri? uri) async {
    return uri?.queryParameters['action'];
  }

  Future<String?> getInitialWidgetAction() async {
    final action = await _methodChannel.invokeMethod<String>(
      'getInitialWidgetAction',
    );
    if (action == null || action.trim().isEmpty) return null;
    await _methodChannel.invokeMethod<void>('resetInitialWidgetAction');
    return action;
  }

  Stream<String> listenForWidgetActions() {
    return _eventChannel.receiveBroadcastStream().where((event) {
      return event is String && event.trim().isNotEmpty;
    }).cast<String>();
  }
}
