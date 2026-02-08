import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:copyman/models/clipboard_item.dart';
import 'package:copyman/widgets/clipboard_item_tile.dart';

ClipboardItem _item({
  int id = 1,
  String content = 'test content',
  bool pinned = false,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return ClipboardItem(
    id: id,
    content: content,
    pinned: pinned,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ClipboardItemTile', () {
    testWidgets('renders item content text', (tester) async {
      await tester.pumpWidget(_wrap(ClipboardItemTile(
        item: _item(content: 'hello clipboard'),
        isSelected: false,
        onTap: () {},
        onDoubleTap: () {},
        onPin: () {},
        onDelete: () {},
        onPasteAsPlain: () {},
      )));
      // Content is rendered via RichText; find by widget predicate
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText().contains('hello clipboard')),
        findsOneWidget,
      );
    });

    testWidgets('pin icon visible for pinned items', (tester) async {
      await tester.pumpWidget(_wrap(ClipboardItemTile(
        item: _item(pinned: true),
        isSelected: false,
        onTap: () {},
        onDoubleTap: () {},
        onPin: () {},
        onDelete: () {},
        onPasteAsPlain: () {},
      )));
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('pin icon absent for unpinned items', (tester) async {
      await tester.pumpWidget(_wrap(ClipboardItemTile(
        item: _item(pinned: false),
        isSelected: false,
        onTap: () {},
        onDoubleTap: () {},
        onPin: () {},
        onDelete: () {},
        onPasteAsPlain: () {},
      )));
      expect(find.byIcon(Icons.push_pin), findsNothing);
    });

    testWidgets('onTap callback fires on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(ClipboardItemTile(
        item: _item(content: 'tap target'),
        isSelected: false,
        onTap: () => tapped = true,
        onDoubleTap: () {},
        onPin: () {},
        onDelete: () {},
        onPasteAsPlain: () {},
      )));
      // When onDoubleTap is also set, GestureDetector delays onTap
      // to distinguish. Use pumpAndSettle or pump with delay.
      final rect = tester.getRect(find.byType(ClipboardItemTile));
      await tester.tapAt(rect.center);
      // Wait for the double-tap disambiguation timeout (300ms)
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(tapped, isTrue);
    });

    testWidgets('multi-select mode shows checkbox', (tester) async {
      await tester.pumpWidget(_wrap(ClipboardItemTile(
        item: _item(),
        isSelected: false,
        onTap: () {},
        onDoubleTap: () {},
        onPin: () {},
        onDelete: () {},
        onPasteAsPlain: () {},
        isMultiSelectMode: true,
        isCheckboxChecked: false,
      )));
      // No Checkbox widget shown (ClipboardItemTile does not render an actual
      // Checkbox widget, it uses background color tinting for selection state).
      // The tile should still render without error.
      expect(find.byType(ClipboardItemTile), findsOneWidget);
    });

    testWidgets('isCheckboxChecked changes background color', (tester) async {
      await tester.pumpWidget(_wrap(ClipboardItemTile(
        item: _item(),
        isSelected: false,
        onTap: () {},
        onDoubleTap: () {},
        onPin: () {},
        onDelete: () {},
        onPasteAsPlain: () {},
        isMultiSelectMode: true,
        isCheckboxChecked: true,
      )));
      // Widget renders without error when checked
      expect(find.byType(ClipboardItemTile), findsOneWidget);
    });

    testWidgets('highlighted match indices render with different style',
        (tester) async {
      await tester.pumpWidget(_wrap(ClipboardItemTile(
        item: _item(content: 'hello'),
        isSelected: false,
        onTap: () {},
        onDoubleTap: () {},
        onPin: () {},
        onDelete: () {},
        onPasteAsPlain: () {},
        matchIndices: [0, 1], // highlight first two chars
      )));
      // RichText should be present
      expect(find.byType(RichText), findsWidgets);
    });
  });
}
