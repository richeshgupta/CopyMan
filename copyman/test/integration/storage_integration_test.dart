import 'package:flutter_test/flutter_test.dart';

import 'package:copyman/services/group_service.dart';
import 'package:copyman/services/storage_service.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestServices();
  });

  setUp(() async {
    await StorageService.instance.deleteAll();
    // Reset TTL settings between tests
    await StorageService.instance.setSetting('ttl_enabled', 'false');
    await StorageService.instance.setSetting('ttl_hours', '72');
  });

  tearDownAll(() async {
    await teardownTestServices();
  });

  group('Storage + Groups integration', () {
    test('items start in Uncategorized group (id 1)', () async {
      await insertTestItem('test item');
      final items = await StorageService.instance.fetchItems();
      expect(items.first.groupId, 1);
    });

    test('moving item to new group changes groupId', () async {
      final groupId = await GroupService.instance.createGroup('Work');
      await insertTestItem('move me');
      final items = await StorageService.instance.fetchItems();
      final itemId = items.first.id;

      await GroupService.instance.moveItemToGroup(itemId, groupId);

      final updated = await GroupService.instance.fetchItemsInGroup(groupId);
      expect(updated.length, 1);
      expect(updated.first.content, 'move me');
    });

    test('deleting group moves items to Uncategorized', () async {
      final groupId = await GroupService.instance.createGroup('Temp');
      await insertTestItem('temp item');
      final items = await StorageService.instance.fetchItems();
      await GroupService.instance.moveItemToGroup(items.first.id, groupId);

      await GroupService.instance.deleteGroup(groupId);

      final remaining = await StorageService.instance.fetchItems();
      expect(remaining.first.groupId, 1);
    });

    test('group item count works correctly', () async {
      await insertTestItem('item 1');
      await insertTestItem('item 2');

      final count = await GroupService.instance.getGroupItemCount(1);
      expect(count, 2);
    });
  });

  group('Storage - Settings persistence', () {
    test('setSetting and getSetting round-trip', () async {
      await StorageService.instance.setSetting('test_key', 'test_value');
      final val = await StorageService.instance.getSetting('test_key');
      expect(val, 'test_value');
    });

    test('setSetting overwrites existing value', () async {
      await StorageService.instance.setSetting('key', 'old');
      await StorageService.instance.setSetting('key', 'new');
      final val = await StorageService.instance.getSetting('key');
      expect(val, 'new');
    });

    test('getSetting returns null for missing key', () async {
      final val = await StorageService.instance.getSetting('nonexistent');
      expect(val, isNull);
    });

    test('history limit persists', () async {
      await StorageService.instance.setHistoryLimit(100);
      final limit = await StorageService.instance.getHistoryLimit();
      expect(limit, 100);
    });
  });

  group('Storage - Exclusions', () {
    test('setting app exclusion makes it blocked', () async {
      await StorageService.instance.setExclusion('TestApp', true);
      final excluded = await StorageService.instance.isAppExcluded('TestApp');
      expect(excluded, isTrue);
    });

    test('removing exclusion unblocks app', () async {
      await StorageService.instance.setExclusion('TestApp', true);
      await StorageService.instance.setExclusion('TestApp', false);
      final excluded = await StorageService.instance.isAppExcluded('TestApp');
      expect(excluded, isFalse);
    });

    test('pre-seeded exclusions exist', () async {
      final excluded = await StorageService.instance.isAppExcluded('Bitwarden');
      expect(excluded, isTrue);
    });

    test('fetchExclusions returns all entries', () async {
      final exclusions = await StorageService.instance.fetchExclusions();
      // Should include pre-seeded entries
      expect(exclusions.length, greaterThanOrEqualTo(8));
    });
  });

  group('Storage - Duplicate handling', () {
    test('inserting duplicate text bumps timestamp', () async {
      final id1 = await StorageService.instance.insertOrUpdate('duplicate');
      await Future.delayed(const Duration(milliseconds: 10));
      final id2 = await StorageService.instance.insertOrUpdate('duplicate');
      expect(id1, id2); // Same row
    });

    test('pin toggle works correctly', () async {
      await insertTestItem('pin test');
      final items = await StorageService.instance.fetchItems();
      expect(items.first.pinned, isFalse);

      await StorageService.instance.togglePin(items.first.id);
      final updated = await StorageService.instance.fetchItems();
      expect(updated.first.pinned, isTrue);

      await StorageService.instance.togglePin(items.first.id);
      final toggled = await StorageService.instance.fetchItems();
      expect(toggled.first.pinned, isFalse);
    });
  });

  group('Storage - TTL auto-clear', () {
    test('clearExpiredItems does nothing when TTL is disabled', () async {
      await insertTestItem('old item');
      await StorageService.instance.clearExpiredItems();
      final items = await StorageService.instance.fetchItems();
      expect(items.length, 1);
    });

    test('clearExpiredItems removes old items when TTL is enabled', () async {
      // Insert item first, then enable TTL
      await StorageService.instance.insertOrUpdate('should be deleted');
      await Future.delayed(const Duration(milliseconds: 10));

      await StorageService.instance.setSetting('ttl_enabled', 'true');
      await StorageService.instance.setSetting('ttl_hours', '0');

      await StorageService.instance.clearExpiredItems();
      final items = await StorageService.instance.fetchItems();
      expect(items.length, 0);
    });

    test('pinned items survive TTL clear', () async {
      // Insert items first, pin one, then enable TTL
      final id1 = await StorageService.instance.insertOrUpdate('pinned item');
      await StorageService.instance.insertOrUpdate('unpinned item');
      await StorageService.instance.togglePin(id1);
      await Future.delayed(const Duration(milliseconds: 10));

      await StorageService.instance.setSetting('ttl_enabled', 'true');
      await StorageService.instance.setSetting('ttl_hours', '0');

      await StorageService.instance.clearExpiredItems();
      final items = await StorageService.instance.fetchItems();
      expect(items.length, 1);
      expect(items.first.content, 'pinned item');
    });
  });
}
