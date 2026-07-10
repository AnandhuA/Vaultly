import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../app/routes.dart';
import '../../core/services/app_navigator.dart';
import '../../core/services/shared_intent_service.dart';
import '../capture/capture_provider.dart';

class SharedIntentProvider extends ChangeNotifier {
  SharedIntentProvider(this._service, this._capture);

  final SharedIntentService _service;
  final CaptureProvider _capture;
  StreamSubscription<SharedIntentPayload>? _subscription;

  Future<void> listen() async {
    await _service.initialize();
    final initial = await _service.getInitialSharedContent();
    if (initial != null) _forward(initial);
    _subscription = _service.listenForSharedContent().listen(_forward);
  }

  void _forward(SharedIntentPayload payload) {
    if (payload.text.trim().isEmpty) return;
    final seed = CaptureSeed(
      text: payload.text,
      filePath: payload.filePath,
      typeHint: payload.typeHint,
    );
    _capture.receive(seed);
    AppNavigator.openCapture(seed);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
