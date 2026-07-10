import 'dart:async';

import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class SharedIntentPayload {
  const SharedIntentPayload({required this.text, this.filePath, this.typeHint});

  final String text;
  final String? filePath;
  final String? typeHint;
}

class SharedIntentService {
  static const _nativeMethodChannel = MethodChannel('vaultly/share_intent');
  static const _nativeEventChannel = EventChannel('vaultly/share_intent_stream');

  StreamSubscription<SharedIntentPayload>? _subscription;

  Future<void> initialize() async {}

  Stream<SharedIntentPayload> listenForSharedContent() {
    final pluginStream = ReceiveSharingIntent.instance.getMediaStream().map(parseSharedContent);
    final nativeStream = _nativeEventChannel.receiveBroadcastStream().map((event) {
      return parseNativePayload(Map<dynamic, dynamic>.from(event as Map));
    });
    return StreamGroup.merge([pluginStream, nativeStream]);
  }

  Stream<SharedIntentPayload> get stream => listenForSharedContent();

  Future<SharedIntentPayload?> getInitialSharedContent() async {
    final nativePayload = await _nativeMethodChannel.invokeMapMethod<String, dynamic>(
      'getInitialShare',
    );
    if (nativePayload != null && (nativePayload['text'] as String?)?.trim().isNotEmpty == true) {
      await _nativeMethodChannel.invokeMethod<void>('resetInitialShare');
      await ReceiveSharingIntent.instance.reset();
      return parseNativePayload(nativePayload);
    }

    final media = await ReceiveSharingIntent.instance.getInitialMedia();
    if (media.isNotEmpty) {
      final payload = parseSharedContent(media);
      await ReceiveSharingIntent.instance.reset();
      await _nativeMethodChannel.invokeMethod<void>('resetInitialShare');
      if (payload.text.trim().isNotEmpty) return payload;
    }
    return null;
  }

  Future<SharedIntentPayload?> initialPayload() => getInitialSharedContent();

  void subscribe(void Function(SharedIntentPayload payload) onPayload) {
    _subscription?.cancel();
    _subscription = listenForSharedContent().listen(onPayload);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  SharedIntentPayload parseSharedContent(List<SharedMediaFile> media) {
    final first = media.first;
    final path = first.path;
    if (path.trim().isEmpty || path == 'null') {
      return const SharedIntentPayload(text: '', typeHint: 'text');
    }
    final lower = '${first.mimeType ?? ''} $path'.toLowerCase();
    final hint = lower.contains('pdf') || lower.endsWith('.pdf')
        ? 'pdf'
        : lower.contains('image/') ||
                lower.endsWith('.png') ||
                lower.endsWith('.jpg') ||
                lower.endsWith('.jpeg')
            ? 'image'
            : lower.contains('video/') || lower.endsWith('.mp4') || lower.endsWith('.mov')
                ? 'video'
                : first.type == SharedMediaType.text
                    ? 'text'
                    : first.type == SharedMediaType.url
                        ? 'link'
            : null;
    final filePath = first.type == SharedMediaType.file ||
            first.type == SharedMediaType.image ||
            first.type == SharedMediaType.video
        ? path
        : null;
    return SharedIntentPayload(text: path, filePath: filePath, typeHint: hint);
  }

  SharedIntentPayload parseNativePayload(Map<dynamic, dynamic> payload) {
    return SharedIntentPayload(
      text: (payload['text'] as String?) ?? '',
      filePath: payload['filePath'] as String?,
      typeHint: payload['typeHint'] as String?,
    );
  }
}

class StreamGroup {
  static Stream<T> merge<T>(Iterable<Stream<T>> streams) {
    late StreamController<T> controller;
    final subscriptions = <StreamSubscription<T>>[];
    var closed = 0;

    controller = StreamController<T>(
      onListen: () {
        for (final stream in streams) {
          subscriptions.add(
            stream.listen(
              controller.add,
              onError: controller.addError,
              onDone: () {
                closed += 1;
                if (closed == streams.length) controller.close();
              },
            ),
          );
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }
}
