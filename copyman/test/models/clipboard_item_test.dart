import 'package:flutter_test/flutter_test.dart';

import 'package:copyman/models/clipboard_item.dart';

void main() {
  group('ClipboardItem.fromMap', () {
    test('deserializes all fields correctly', () {
      final map = {
        'id': 42,
        'content': 'hello world',
        'type': 'text',
        'pinned': 1,
        'created_at': 1000000,
        'updated_at': 2000000,
        'content_bytes': null,
        'content_hash': 'abc123',
        'group_id': 2,
      };
      final item = ClipboardItem.fromMap(map);
      expect(item.id, 42);
      expect(item.content, 'hello world');
      expect(item.type, 'text');
      expect(item.pinned, isTrue);
      expect(item.createdAt, 1000000);
      expect(item.updatedAt, 2000000);
      expect(item.contentBytes, isNull);
      expect(item.contentHash, 'abc123');
      expect(item.groupId, 2);
    });

    test('pinned=0 deserializes to false', () {
      final map = {
        'id': 1,
        'content': 'x',
        'type': 'text',
        'pinned': 0,
        'created_at': 0,
        'updated_at': 0,
      };
      final item = ClipboardItem.fromMap(map);
      expect(item.pinned, isFalse);
    });
  });

  group('ClipboardItem.relativeTime', () {
    ClipboardItem itemWithAge(int milliseconds) {
      final now = DateTime.now().millisecondsSinceEpoch;
      return ClipboardItem(
        id: 1,
        content: 'test',
        createdAt: now - milliseconds,
        updatedAt: now - milliseconds,
      );
    }

    test('returns "just now" within 60 seconds', () {
      expect(itemWithAge(0).relativeTime, 'just now');
      expect(itemWithAge(30000).relativeTime, 'just now');
      expect(itemWithAge(59999).relativeTime, 'just now');
    });

    test('returns "Xm ago" for 1-59 minutes', () {
      expect(itemWithAge(60000).relativeTime, '1m ago');
      expect(itemWithAge(5 * 60000).relativeTime, '5m ago');
      expect(itemWithAge(59 * 60000).relativeTime, '59m ago');
    });

    test('returns "Xh ago" for 1-23 hours', () {
      expect(itemWithAge(3600000).relativeTime, '1h ago');
      expect(itemWithAge(2 * 3600000).relativeTime, '2h ago');
      expect(itemWithAge(23 * 3600000).relativeTime, '23h ago');
    });

    test('returns "Xd ago" for 1+ days', () {
      expect(itemWithAge(86400000).relativeTime, '1d ago');
      expect(itemWithAge(3 * 86400000).relativeTime, '3d ago');
    });
  });

  group('ClipboardItem.isSensitive', () {
    test('returns true for text containing secrets', () {
      final item = ClipboardItem(
        id: 1,
        content: 'password: hunter2',
        createdAt: 0,
        updatedAt: 0,
      );
      expect(item.isSensitive, isTrue);
    });

    test('returns false for normal text and image items', () {
      final textItem = ClipboardItem(
        id: 1,
        content: 'Hello world',
        createdAt: 0,
        updatedAt: 0,
      );
      expect(textItem.isSensitive, isFalse);

      final imageItem = ClipboardItem(
        id: 2,
        content: 'password: hunter2',
        type: 'image',
        createdAt: 0,
        updatedAt: 0,
      );
      expect(imageItem.isSensitive, isFalse);
    });
  });
}
