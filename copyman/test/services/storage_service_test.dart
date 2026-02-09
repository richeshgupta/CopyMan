import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:copyman/services/storage_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    await StorageService.instance.initForTest(':memory:');
  });

  tearDown(() async {
    await StorageService.instance.close();
  });

  group('StorageService - insertOrUpdate', () {
    test('inserts new item and returns an int id', () async {
      final id = await StorageService.instance.insertOrUpdate('hello');
      expect(id, isA<int>());
      expect(id, greaterThan(0));
    });

    test('second call with same content bumps updated_at, no duplicate', () async {
      await StorageService.instance.insertOrUpdate('dup');
      // Brief pause to ensure timestamp differs
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await StorageService.instance.insertOrUpdate('dup');
      final items = await StorageService.instance.fetchItems();
      expect(items.where((i) => i.content == 'dup').length, 1);
    });
  });

  group('StorageService - fetchItems', () {
    test('returns items ordered by pinned DESC, updated_at DESC', () async {
      await StorageService.instance.insertOrUpdate('first');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final secondId = await StorageService.instance.insertOrUpdate('second');
      await StorageService.instance.togglePin(secondId);

      final items = await StorageService.instance.fetchItems();
      expect(items.first.content, 'second'); // pinned comes first
      expect(items.first.pinned, isTrue);
    });
  });

  group('StorageService - togglePin', () {
    test('flips pinned state', () async {
      final id = await StorageService.instance.insertOrUpdate('pin test');
      var items = await StorageService.instance.fetchItems();
      expect(items.first.pinned, isFalse);

      await StorageService.instance.togglePin(id);
      items = await StorageService.instance.fetchItems();
      expect(items.first.pinned, isTrue);

      await StorageService.instance.togglePin(id);
      items = await StorageService.instance.fetchItems();
      expect(items.first.pinned, isFalse);
    });
  });

  group('StorageService - deleteItem / deleteAll', () {
    test('deleteItem removes the item', () async {
      final id = await StorageService.instance.insertOrUpdate('to delete');
      await StorageService.instance.deleteItem(id);
      final items = await StorageService.instance.fetchItems();
      expect(items.any((i) => i.id == id), isFalse);
    });

    test('deleteAll clears the table', () async {
      await StorageService.instance.insertOrUpdate('a');
      await StorageService.instance.insertOrUpdate('b');
      await StorageService.instance.deleteAll();
      final items = await StorageService.instance.fetchItems();
      expect(items, isEmpty);
    });
  });

  group('StorageService - settings', () {
    test('setSetting / getSetting round-trips string values', () async {
      await StorageService.instance.setSetting('my_key', 'my_value');
      final val = await StorageService.instance.getSetting('my_key');
      expect(val, 'my_value');
    });

    test('getSetting returns null for missing key', () async {
      final val = await StorageService.instance.getSetting('nonexistent');
      expect(val, isNull);
    });
  });

  group('StorageService - app exclusions', () {
    test('isAppExcluded returns true for seeded apps', () async {
      expect(await StorageService.instance.isAppExcluded('1Password'), isTrue);
      expect(await StorageService.instance.isAppExcluded('Bitwarden'), isTrue);
    });

    test('setExclusion with blocked=false removes entry', () async {
      await StorageService.instance.setExclusion('1Password', false);
      expect(await StorageService.instance.isAppExcluded('1Password'), isFalse);
    });

    test('setExclusion with blocked=true adds entry', () async {
      await StorageService.instance.setExclusion('NewApp', true);
      expect(await StorageService.instance.isAppExcluded('NewApp'), isTrue);
    });
  });

  group('StorageService - TTL / clearExpiredItems', () {
    test('clearExpiredItems does nothing when ttl_enabled is not "true"', () async {
      await StorageService.instance.insertOrUpdate('keep me');
      await StorageService.instance.clearExpiredItems();
      final items = await StorageService.instance.fetchItems();
      expect(items.isNotEmpty, isTrue);
    });

    test('clearExpiredItems removes old items when enabled', () async {
      await StorageService.instance.setSetting('ttl_enabled', 'true');
      await StorageService.instance.setSetting('ttl_hours', '1');

      // Insert item with very old timestamp directly
      final oldTime = DateTime.now()
          .subtract(const Duration(hours: 2))
          .millisecondsSinceEpoch;
      await StorageService.instance.db.insert('clipboard_items', {
        'content': 'old item',
        'type': 'text',
        'pinned': 0,
        'created_at': oldTime,
        'updated_at': oldTime,
      });

      await StorageService.instance.clearExpiredItems();
      final items = await StorageService.instance.fetchItems();
      expect(items.any((i) => i.content == 'old item'), isFalse);
    });
  });

  group('StorageService - image deduplication', () {
    test('inserts image item with bytes and hash', () async {
      final bytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]); // PNG header
      final id = await StorageService.instance.insertOrUpdate(
        '[Image 8 B]',
        type: 'image',
        contentBytes: bytes,
        contentHash: 'abc123hash',
      );
      expect(id, greaterThan(0));

      final items = await StorageService.instance.fetchItems();
      expect(items.length, 1);
      expect(items.first.type, 'image');
      expect(items.first.contentBytes, bytes);
      expect(items.first.contentHash, 'abc123hash');
    });

    test('deduplicates images by hash, not content text', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      await StorageService.instance.insertOrUpdate(
        '[Image 3 B]',
        type: 'image',
        contentBytes: bytes,
        contentHash: 'samehash',
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      // Same hash, different content text — should deduplicate
      final id2 = await StorageService.instance.insertOrUpdate(
        '[Image 3 B] different label',
        type: 'image',
        contentBytes: bytes,
        contentHash: 'samehash',
      );

      final items = await StorageService.instance.fetchItems();
      expect(items.length, 1);
      expect(id2, items.first.id); // bumped, not new
    });

    test('different hashes create separate items', () async {
      final bytes1 = Uint8List.fromList([1]);
      final bytes2 = Uint8List.fromList([2]);
      await StorageService.instance.insertOrUpdate(
        '[Image]',
        type: 'image',
        contentBytes: bytes1,
        contentHash: 'hash1',
      );
      await StorageService.instance.insertOrUpdate(
        '[Image]',
        type: 'image',
        contentBytes: bytes2,
        contentHash: 'hash2',
      );

      final items = await StorageService.instance.fetchItems();
      expect(items.length, 2);
    });
  });
}
