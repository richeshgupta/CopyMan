import 'package:flutter_test/flutter_test.dart';

import 'package:copyman/models/clipboard_item.dart';
import 'package:copyman/models/sequence_session.dart';

ClipboardItem _item(int id, String content) => ClipboardItem(
      id: id,
      content: content,
      createdAt: 0,
      updatedAt: 0,
    );

void main() {
  group('SequenceSession', () {
    test('currentItem returns item at current index', () {
      final items = [_item(1, 'a'), _item(2, 'b'), _item(3, 'c')];
      final session = SequenceSession(items: items);
      expect(session.currentItem.content, 'a');
    });

    test('advance() increments index', () {
      final items = [_item(1, 'a'), _item(2, 'b'), _item(3, 'c')];
      final session = SequenceSession(items: items);
      session.advance();
      expect(session.currentItem.content, 'b');
      session.advance();
      expect(session.currentItem.content, 'c');
    });

    test('hasNext is false at last item', () {
      final items = [_item(1, 'a'), _item(2, 'b')];
      final session = SequenceSession(items: items);
      expect(session.hasNext, isTrue);
      session.advance();
      expect(session.hasNext, isFalse);
    });

    test('isComplete is true only after advancing past last item', () {
      final items = [_item(1, 'a'), _item(2, 'b')];
      final session = SequenceSession(items: items);
      expect(session.isComplete, isFalse);
      // advance() only moves to next while hasNext; cannot go past last via advance()
      // isComplete checks currentIndex >= items.length
      session.currentIndex = items.length;
      expect(session.isComplete, isTrue);
    });

    test('progress returns "1/3" style strings', () {
      final items = [_item(1, 'a'), _item(2, 'b'), _item(3, 'c')];
      final session = SequenceSession(items: items);
      expect(session.progress, '1/3');
      session.advance();
      expect(session.progress, '2/3');
      session.advance();
      expect(session.progress, '3/3');
    });

    test('constructor assertion fires on empty list', () {
      expect(
        () => SequenceSession(items: []),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
