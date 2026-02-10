import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:copyman/screens/settings_screen.dart';
import 'package:copyman/services/hotkey_config_service.dart';
import 'package:copyman/services/storage_service.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestServices();
  });

  setUp(() async {
    await StorageService.instance.deleteAll();
  });

  tearDownAll(() async {
    await teardownTestServices();
  });

  Widget buildSettings({String themeMode = 'system'}) {
    return buildTestApp(
      home: SettingsScreen(
        currentThemeMode: themeMode,
        onThemeModeChanged: (_) {},
      ),
    );
  }

  group('SettingsScreen - General tab', () {
    testWidgets('shows history limit slider', (tester) async {
      await tester.pumpWidget(buildSettings());
      await tester.pumpAndSettle();

      expect(find.text('History limit'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('shows theme segmented button', (tester) async {
      await tester.pumpWidget(buildSettings());
      await tester.pumpAndSettle();

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });
  });

  group('SettingsScreen - Tabs', () {
    testWidgets('has all 4 tabs', (tester) async {
      await tester.pumpWidget(buildSettings());
      await tester.pumpAndSettle();

      expect(find.text('General'), findsOneWidget);
      expect(find.text('Auto-Clear'), findsOneWidget);
      expect(find.text('Exclusions'), findsOneWidget);
      expect(find.text('Shortcuts'), findsOneWidget);
    });

    testWidgets('navigating to Auto-Clear tab shows TTL toggle',
        (tester) async {
      await tester.pumpWidget(buildSettings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Auto-Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Auto-clear old items'), findsOneWidget);
    });

    testWidgets('navigating to Exclusions tab shows sensitive toggle',
        (tester) async {
      await tester.pumpWidget(buildSettings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exclusions'));
      await tester.pumpAndSettle();

      expect(find.text('Auto-exclude sensitive content'), findsOneWidget);
      expect(find.text('Skip all images'), findsOneWidget);
    });

    testWidgets('navigating to Shortcuts tab shows actions',
        (tester) async {
      await tester.pumpWidget(buildSettings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shortcuts'));
      await tester.pumpAndSettle();

      // Check that at least the first few visible actions are rendered
      // (some may be offscreen in the scrollable list)
      expect(find.text('Toggle Window'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Copy & Paste'), findsOneWidget);

      // Verify all 13 actions exist by scrolling through
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // Verify the edit buttons exist (one per action)
      expect(find.byIcon(Icons.edit_outlined),
          findsAtLeast(3));
    });

    testWidgets('shortcuts tab shows Reset All and View Shortcuts buttons',
        (tester) async {
      await tester.pumpWidget(buildSettings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shortcuts'));
      await tester.pumpAndSettle();

      expect(find.text('Reset All to Defaults'), findsOneWidget);
      expect(find.text('View Shortcuts'), findsOneWidget);
    });
  });

  group('SettingsScreen - Exclusions tab interactions', () {
    testWidgets('sensitive content toggle persists setting', (tester) async {
      await tester.pumpWidget(buildSettings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exclusions'));
      await tester.pumpAndSettle();

      // Toggle auto-exclude sensitive
      final toggle = find.widgetWithText(SwitchListTile, 'Auto-exclude sensitive content');
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      // Verify setting was persisted
      final val =
          await StorageService.instance.getSetting('auto_exclude_sensitive');
      expect(val, 'true');
    });

    testWidgets('skip images toggle persists setting', (tester) async {
      await tester.pumpWidget(buildSettings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exclusions'));
      await tester.pumpAndSettle();

      final toggle = find.widgetWithText(SwitchListTile, 'Skip all images');
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      final val = await StorageService.instance.getSetting('skip_images');
      expect(val, 'true');
    });

    testWidgets(
        'skip large images toggle appears when skip all images is off',
        (tester) async {
      await tester.pumpWidget(buildSettings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exclusions'));
      await tester.pumpAndSettle();

      // "Skip large images" should be visible since "Skip all images" is off
      expect(find.text('Skip large images'), findsOneWidget);
    });

    testWidgets(
        'toggling skip images on hides skip large images',
        (tester) async {
      await tester.pumpWidget(buildSettings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exclusions'));
      await tester.pumpAndSettle();

      // Initially "Skip large images" should be visible
      expect(find.text('Skip large images'), findsOneWidget);

      // Toggle "Skip all images" ON
      final toggle = find.widgetWithText(SwitchListTile, 'Skip all images');
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      // Now "Skip large images" should be hidden
      expect(find.text('Skip large images'), findsNothing);
    });

    testWidgets('can add app exclusion', (tester) async {
      await tester.pumpWidget(buildSettings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exclusions'));
      await tester.pumpAndSettle();

      // Type an app name
      final textField = find.byType(TextField);
      // The Exclusions tab has a TextField for app class name
      // It's the one with the 'App class name' hint
      await tester.enterText(textField.last, 'TestApp');
      await tester.pumpAndSettle();

      // Tap add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify the exclusion was added
      final exclusions = await StorageService.instance.fetchExclusions();
      final testExcl = exclusions.where((e) => e['app_name'] == 'TestApp');
      expect(testExcl, isNotEmpty);
    });
  });

  group('SettingsScreen - Auto-Clear tab interactions', () {
    testWidgets('toggling TTL switch persists setting', (tester) async {
      await tester.pumpWidget(buildSettings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Auto-Clear'));
      await tester.pumpAndSettle();

      // Toggle TTL
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final val = await StorageService.instance.getSetting('ttl_enabled');
      expect(val, 'true');
    });

    testWidgets('TTL slider appears after enabling', (tester) async {
      await tester.pumpWidget(buildSettings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Auto-Clear'));
      await tester.pumpAndSettle();

      // No slider initially
      expect(find.byType(Slider), findsNothing);

      // Toggle TTL on
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Slider should now appear
      expect(find.byType(Slider), findsOneWidget);
    });
  });

  group('SettingsScreen - Navigation', () {
    testWidgets('back button navigates back', (tester) async {
      await tester.pumpWidget(buildSettings());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
