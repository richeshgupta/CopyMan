import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:copyman/services/hotkey_config_service.dart';
import 'package:copyman/widgets/shortcuts_help_overlay.dart';

void main() {
  // Initialize bindings with defaults for testing
  setUpAll(() {
    final config = HotkeyConfigService.instance;
    for (final action in AppAction.values) {
      // Ensure bindings are populated (normally done via init)
      config.setBindingForTest(
        action,
        config.getBinding(action),
      );
    }
  });

  group('ShortcutsHelpOverlay', () {
    testWidgets('renders all 13 shortcut descriptions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShortcutsHelpOverlay(onClose: () {}),
          ),
        ),
      );

      // Check all 13 action display names are present
      for (final action in AppAction.values) {
        final name = HotkeyConfigService.actionDisplayName(action);
        expect(find.text(name), findsOneWidget, reason: 'Missing: $name');
      }
    });

    testWidgets('renders category headers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShortcutsHelpOverlay(onClose: () {}),
          ),
        ),
      );

      expect(find.text('Global'), findsOneWidget);
      expect(find.text('Navigation'), findsOneWidget);
      expect(find.text('Actions'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
    });

    testWidgets('close button calls onClose', (tester) async {
      var closed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShortcutsHelpOverlay(onClose: () => closed = true),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(closed, isTrue);
    });
  });
}
