import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:copyman/services/clipboard_service.dart';
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
    mockClipboard();
  });

  tearDownAll(() async {
    await teardownTestServices();
  });

  Widget buildApp() => buildTestApp(home: const TestableHomeScreen());

  group('Sensitive content - Display', () {
    testWidgets('AWS key shows lock icon', (tester) async {
      await insertTestItem('AKIAIOSFODNN7EXAMPLE');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('GitHub token shows lock icon', (tester) async {
      await insertTestItem(
          'ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('JWT shows lock icon', (tester) async {
      await insertTestItem(
          'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('SSH private key shows lock icon', (tester) async {
      await insertTestItem('-----BEGIN RSA PRIVATE KEY-----');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('password pattern shows lock icon', (tester) async {
      await insertTestItem('password: mysecret123');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('DB connection string shows lock icon', (tester) async {
      await insertTestItem('postgresql://user:pass@localhost:5432/db');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('normal text does not show lock icon', (tester) async {
      await insertTestItem('Hello, this is normal text');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });

    testWidgets('mixed sensitive and normal items show correct icons',
        (tester) async {
      await insertTestItem('password: secret');
      await insertTestItem('Normal text');
      await insertTestItem('api_key=abc123');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(ClipboardItemTile), findsNWidgets(3));
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
    });
  });

  group('Sensitive content - Auto-exclusion', () {
    testWidgets('sensitive content is stored when auto-exclude is off',
        (tester) async {
      // Make sure auto-exclude is off
      await StorageService.instance
          .setSetting('auto_exclude_sensitive', 'false');

      final clipService = ClipboardService();
      clipService.imageReaderOverride = () async => null;

      // Manually insert a sensitive item (simulating what poll would do)
      await StorageService.instance.insertOrUpdate('password: hunter2');

      final items = await StorageService.instance.fetchItems();
      expect(items.length, 1);
      expect(items.first.content, 'password: hunter2');

      clipService.dispose();
    });

    testWidgets('auto-exclude setting persists in DB', (tester) async {
      await StorageService.instance
          .setSetting('auto_exclude_sensitive', 'true');

      final val =
          await StorageService.instance.getSetting('auto_exclude_sensitive');
      expect(val, 'true');
    });
  });
}
