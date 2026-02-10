import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:copyman/services/group_service.dart';
import 'package:copyman/services/storage_service.dart';
import 'package:copyman/widgets/clipboard_item_tile.dart';

import 'test_helpers.dart';
import 'testable_home_screen.dart';

void main() {
  setUpAll(() async {
    await initTestServices();
  });

  setUp(() async {
    await StorageService.instance.deleteAll();
    // Delete all non-default groups
    final groups = await GroupService.instance.fetchAllGroups();
    for (final g in groups) {
      if (g.id != 1) {
        await GroupService.instance.deleteGroup(g.id);
      }
    }
    mockClipboard();
  });

  tearDownAll(() async {
    await teardownTestServices();
  });

  Widget buildApp() => buildTestApp(home: const TestableHomeScreen());

  group('Groups - Filter chips', () {
    testWidgets('group chips not shown with only default group',
        (tester) async {
      await insertTestItem('test');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Only 1 group (Uncategorized), chips should not show
      expect(find.text('All'), findsNothing);
    });

    testWidgets('group chips shown when multiple groups exist',
        (tester) async {
      await GroupService.instance.createGroup('Work');
      await insertTestItem('test');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('selecting group chip filters items', (tester) async {
      final workId = await GroupService.instance.createGroup('Work');
      await insertTestItem('work item');
      await insertTestItem('personal item');

      // Move first item to Work group
      final items = await StorageService.instance.fetchItems();
      final workItem = items.firstWhere((i) => i.content == 'work item');
      await GroupService.instance.moveItemToGroup(workItem.id, workId);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // All items visible initially
      expect(find.byType(ClipboardItemTile), findsNWidgets(2));

      // Tap "Work" chip
      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();

      // Only work item should be visible
      expect(find.byType(ClipboardItemTile), findsOneWidget);
    });

    testWidgets('tapping All chip shows all items', (tester) async {
      await GroupService.instance.createGroup('Work');
      await insertTestItem('item 1');
      await insertTestItem('item 2');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap Work then All
      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.byType(ClipboardItemTile), findsNWidgets(2));
    });
  });

  group('Groups - Creation', () {
    testWidgets('add group chip (+) opens dialog', (tester) async {
      // Need a second group so chips show up
      await GroupService.instance.createGroup('Existing');
      await insertTestItem('test');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap the + chip
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('New Group'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('creating group via service adds it to DB', (tester) async {
      // Test group creation at the service level
      final id = await GroupService.instance.createGroup('Brand New');
      expect(id, greaterThan(1));

      final groups = await GroupService.instance.fetchAllGroups();
      final names = groups.map((g) => g.name).toList();
      expect(names, contains('Brand New'));
    });
  });
}
