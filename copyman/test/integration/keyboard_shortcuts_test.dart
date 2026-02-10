import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:copyman/services/storage_service.dart';
import 'package:copyman/widgets/clipboard_item_tile.dart';
import 'package:copyman/widgets/shortcuts_help_overlay.dart';

import 'test_helpers.dart';
import 'testable_home_screen.dart';

void main() {
  setUpAll(() async {
    await initTestServices();
  });

  setUp(() async {
    await StorageService.instance.deleteAll();
    mockClipboard();
  });

  tearDownAll(() async {
    await teardownTestServices();
  });

  Widget buildApp() => buildTestApp(home: const TestableHomeScreen());

  group('Keyboard shortcuts - Navigation', () {
    testWidgets('Arrow Down moves selection down', (tester) async {
      await insertTestItem('Item 1');
      await insertTestItem('Item 2');
      await insertTestItem('Item 3');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final state = tester
          .state<TestableHomeScreenState>(find.byType(TestableHomeScreen));
      expect(state.selectedIndex, 0);

      // Press Arrow Down
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(state.selectedIndex, 1);

      // Press Arrow Down again
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(state.selectedIndex, 2);
    });

    testWidgets('Arrow Up moves selection up', (tester) async {
      await insertTestItem('Item 1');
      await insertTestItem('Item 2');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Move to second item first
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      final state = tester
          .state<TestableHomeScreenState>(find.byType(TestableHomeScreen));
      expect(state.selectedIndex, 1);

      // Move back up
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      expect(state.selectedIndex, 0);
    });

    testWidgets('Arrow Down does not go past last item', (tester) async {
      await insertTestItem('Only item');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      final state = tester
          .state<TestableHomeScreenState>(find.byType(TestableHomeScreen));
      expect(state.selectedIndex, 0);
    });

    testWidgets('Arrow Up does not go below 0', (tester) async {
      await insertTestItem('Only item');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      final state = tester
          .state<TestableHomeScreenState>(find.byType(TestableHomeScreen));
      expect(state.selectedIndex, 0);
    });
  });

  group('Keyboard shortcuts - Actions', () {
    testWidgets('Enter copies selected item to clipboard', (tester) async {
      await insertTestItem('Copy this text');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Press Enter (copy action)
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      final data = await Clipboard.getData('text/plain');
      expect(data?.text, 'Copy this text');
    });

    testWidgets('Delete key removes selected item', (tester) async {
      await insertTestItem('Delete me');
      await insertTestItem('Keep me');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(ClipboardItemTile), findsNWidgets(2));

      // Press Delete
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();

      expect(find.byType(ClipboardItemTile), findsOneWidget);
    });

    testWidgets('Ctrl+P toggles pin on selected item', (tester) async {
      await insertTestItem('Pin me');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.push_pin), findsNothing);

      // Press Ctrl+P
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('Ctrl+A selects all items', (tester) async {
      await insertTestItem('Item 1');
      await insertTestItem('Item 2');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final state = tester
          .state<TestableHomeScreenState>(find.byType(TestableHomeScreen));
      expect(state.itemSelected.any((x) => x), isFalse);

      // Press Ctrl+A
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(state.itemSelected.every((x) => x), isTrue);
    });

    testWidgets('Ctrl+A toggles off if all already selected', (tester) async {
      await insertTestItem('Item 1');
      await insertTestItem('Item 2');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Select all
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      final state = tester
          .state<TestableHomeScreenState>(find.byType(TestableHomeScreen));
      expect(state.itemSelected.every((x) => x), isTrue);

      // Deselect all
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(state.itemSelected.any((x) => x), isFalse);
    });
  });

  group('Keyboard shortcuts - Preview overlay', () {
    testWidgets('Space toggles preview overlay', (tester) async {
      await insertTestItem('Preview me');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final state = tester
          .state<TestableHomeScreenState>(find.byType(TestableHomeScreen));
      expect(state.previewVisible, isFalse);

      // Press Space (with empty search)
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(state.previewVisible, isTrue);

      // Press Space again to close
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(state.previewVisible, isFalse);
    });

    testWidgets('Escape closes preview overlay', (tester) async {
      await insertTestItem('Preview me');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Open preview
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      final state = tester
          .state<TestableHomeScreenState>(find.byType(TestableHomeScreen));
      expect(state.previewVisible, isTrue);

      // Press Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(state.previewVisible, isFalse);
    });

    testWidgets('Arrow keys close preview', (tester) async {
      await insertTestItem('Item 1');
      await insertTestItem('Item 2');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Open preview
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      final state = tester
          .state<TestableHomeScreenState>(find.byType(TestableHomeScreen));
      expect(state.previewVisible, isTrue);

      // Arrow down should close preview
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(state.previewVisible, isFalse);
    });
  });

  group('Keyboard shortcuts - Help overlay', () {
    testWidgets('Shift+/ opens shortcuts help overlay', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final state = tester
          .state<TestableHomeScreenState>(find.byType(TestableHomeScreen));
      expect(state.helpVisible, isFalse);

      // Press Shift+/ (which is ?)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      expect(state.helpVisible, isTrue);
      expect(find.text('Keyboard Shortcuts'), findsOneWidget);
    });

    testWidgets('help overlay shows all shortcut categories', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Open help overlay
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      expect(find.text('Global'), findsOneWidget);
      expect(find.text('Navigation'), findsOneWidget);
      expect(find.text('Actions'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
    });

    testWidgets('close button on help overlay closes it', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Open help
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      final state = tester
          .state<TestableHomeScreenState>(find.byType(TestableHomeScreen));
      expect(state.helpVisible, isTrue);

      // Find and tap close button on the overlay
      // The ShortcutsHelpOverlay has an IconButton with Icons.close
      final closeButtons = find.descendant(
        of: find.byType(ShortcutsHelpOverlay),
        matching: find.byIcon(Icons.close),
      );
      await tester.tap(closeButtons.first);
      await tester.pumpAndSettle();

      expect(state.helpVisible, isFalse);
    });

    testWidgets('Shift+/ toggles help overlay off', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Open
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      final state = tester
          .state<TestableHomeScreenState>(find.byType(TestableHomeScreen));
      expect(state.helpVisible, isTrue);

      // Close with same shortcut
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      expect(state.helpVisible, isFalse);
    });
  });
}
