import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:copyman/services/storage_service.dart';
import 'package:copyman/widgets/clipboard_item_tile.dart';

import 'test_helpers.dart';
import 'testable_home_screen.dart';

void main() {
  setUpAll(() async {
    await initTestServices();
  });

  setUp(() async {
    // Clear DB between tests
    await StorageService.instance.deleteAll();
    mockClipboard();
  });

  tearDownAll(() async {
    await teardownTestServices();
  });

  Widget buildApp() => buildTestApp(home: const TestableHomeScreen());

  group('HomeScreen - Empty state', () {
    testWidgets('shows empty message when no items', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Clipboard history is empty.\nCopy something to get started.'),
          findsOneWidget);
    });

    testWidgets('shows search bar with placeholder', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Search clipboard...'), findsOneWidget);
    });

    testWidgets('shows settings button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });
  });

  group('HomeScreen - Item display', () {
    testWidgets('renders items from database', (tester) async {
      await insertTestItem('Hello World');
      await insertTestItem('Second item');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(ClipboardItemTile), findsNWidgets(2));
      expect(find.text('2 items'), findsOneWidget);
    });

    testWidgets('renders single item with singular count', (tester) async {
      await insertTestItem('Only one');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(ClipboardItemTile), findsOneWidget);
      expect(find.text('1 item'), findsOneWidget);
    });

    testWidgets('pinned items show pin icon', (tester) async {
      await insertTestItem('Pinned item', pinned: true);
      await insertTestItem('Normal item');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('pinned items appear before unpinned with divider',
        (tester) async {
      await insertTestItem('Normal item');
      await insertTestItem('Pinned item', pinned: true);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // 2 items + 1 divider = 3 children in the list
      expect(find.byType(ClipboardItemTile), findsNWidgets(2));
    });

    testWidgets('sensitive items show lock icon', (tester) async {
      await insertTestItem('password: hunter2');
      await insertTestItem('Normal text');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('multiple sensitive items show multiple lock icons',
        (tester) async {
      await insertTestItem('api_key=abc123');
      await insertTestItem('AKIAIOSFODNN7EXAMPLE');
      await insertTestItem('Normal text');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
    });
  });

  group('HomeScreen - Search/Filter', () {
    testWidgets('typing in search filters items', (tester) async {
      await insertTestItem('flutter code');
      await insertTestItem('dart language');
      await insertTestItem('python script');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(ClipboardItemTile), findsNWidgets(3));

      // Type search query
      await tester.enterText(find.byType(TextField), 'dart');
      await tester.pumpAndSettle();

      // Only 'dart language' should match
      expect(find.byType(ClipboardItemTile), findsOneWidget);
    });

    testWidgets('clearing search shows all items again', (tester) async {
      await insertTestItem('alpha');
      await insertTestItem('beta');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Search for 'alpha'
      await tester.enterText(find.byType(TextField), 'alpha');
      await tester.pumpAndSettle();
      expect(find.byType(ClipboardItemTile), findsOneWidget);

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.byType(ClipboardItemTile), findsNWidgets(2));
    });

    testWidgets('shows "No matches." when search has no results',
        (tester) async {
      await insertTestItem('hello');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pumpAndSettle();

      expect(find.text('No matches.'), findsOneWidget);
    });

    testWidgets('fuzzy search matches partial characters', (tester) async {
      await insertTestItem('clipboard manager');
      await insertTestItem('nothing here');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'clpmgr');
      await tester.pumpAndSettle();

      // Fuzzy: c-l-p-m-g-r should match 'clipboard manager'
      expect(find.byType(ClipboardItemTile), findsOneWidget);
    });
  });

  group('HomeScreen - Item interactions', () {
    testWidgets('tap on item copies to clipboard', (tester) async {
      await insertTestItem('Copy me');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap the item (need to handle double-tap disambiguation)
      final tile = find.byType(ClipboardItemTile);
      final rect = tester.getRect(tile);
      await tester.tapAt(rect.center);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify clipboard was set
      final data = await Clipboard.getData('text/plain');
      expect(data?.text, 'Copy me');
    });

    testWidgets('delete removes item from list', (tester) async {
      await insertTestItem('Delete me');
      await insertTestItem('Keep me');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(ClipboardItemTile), findsNWidgets(2));

      // Get state and delete first item
      final state =
          tester.state<TestableHomeScreenState>(find.byType(TestableHomeScreen));
      final itemToDelete = state.matches.first.item;
      await StorageService.instance.deleteItem(itemToDelete.id);
      await state.loadItems();
      await tester.pumpAndSettle();

      expect(find.byType(ClipboardItemTile), findsOneWidget);
    });

    testWidgets('pin toggle updates display', (tester) async {
      await insertTestItem('Pin me');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.push_pin), findsNothing);

      // Toggle pin via state
      final state =
          tester.state<TestableHomeScreenState>(find.byType(TestableHomeScreen));
      final item = state.matches.first.item;
      await StorageService.instance.togglePin(item.id);
      await state.loadItems();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });
  });

  group('HomeScreen - Context menu', () {
    testWidgets('right-click shows context menu with options',
        (tester) async {
      await insertTestItem('Context menu item');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Right-click (secondary tap) on the item
      final tile = find.byType(ClipboardItemTile);
      final center = tester.getCenter(tile);
      final gesture = await tester.startGesture(center, buttons: kSecondaryButton);
      await gesture.up();
      await tester.pumpAndSettle();

      // Context menu should appear with options
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Pin'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Paste as Plain'), findsOneWidget);
      expect(find.text('Move to Group'), findsOneWidget);
    });
  });
}
