import 'package:flutter_test/flutter_test.dart';

import 'package:copyman/models/clipboard_item.dart';
import 'package:copyman/services/sequence_service.dart';

ClipboardItem _item(int id, String content) => ClipboardItem(
      id: id,
      content: content,
      createdAt: 0,
      updatedAt: 0,
    );

void main() {
  group('SequenceService', () {
    late SequenceService service;

    setUp(() {
      service = SequenceService();
    });

    test('startSequence with 1 item throws ArgumentError', () {
      expect(
        () => service.startSequence([_item(1, 'a')]),
        throwsArgumentError,
      );
    });

    test('startSequence with 2+ items sets isActive = true', () {
      service.startSequence([_item(1, 'a'), _item(2, 'b')]);
      expect(service.isActive, isTrue);
    });

    test('advance moves to next item', () {
      service.startSequence([_item(1, 'a'), _item(2, 'b'), _item(3, 'c')]);
      expect(service.getCurrentItem()!.content, 'a');
      service.advance();
      expect(service.getCurrentItem()!.content, 'b');
    });

    test('isComplete after manually advancing past last item', () {
      service.startSequence([_item(1, 'a'), _item(2, 'b')]);
      expect(service.isComplete, isFalse);
      // Manually set index past end
      service.session!.currentIndex = 2;
      expect(service.isComplete, isTrue);
    });

    test('cancel sets isActive = false and clears session', () {
      service.startSequence([_item(1, 'a'), _item(2, 'b')]);
      service.cancel();
      expect(service.isActive, isFalse);
      expect(service.session, isNull);
    });

    test('progress reflects current position', () {
      service.startSequence([_item(1, 'a'), _item(2, 'b'), _item(3, 'c')]);
      expect(service.progress, '1/3');
      service.advance();
      expect(service.progress, '2/3');
    });

    test('hasNext is false when not active', () {
      expect(service.hasNext, isFalse);
    });

    test('progress returns empty string when not active', () {
      expect(service.progress, '');
    });
  });
}
