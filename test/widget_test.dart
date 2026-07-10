// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:vaultly/core/services/content_detection_service.dart';
import 'package:vaultly/data/models/vault_item.dart';

void main() {
  test('detects YouTube links', () {
    final result = ContentDetectionService.detect('https://youtu.be/example');

    expect(result.sourceApp, 'YouTube');
    expect(result.itemType, VaultItemType.youtube);
  });

  test('suggests Flutter collection from keywords', () {
    final collection = ContentDetectionService.suggestCollection(
      'Provider architecture for Flutter and Firebase',
    );

    expect(collection, 'Flutter');
  });
}
