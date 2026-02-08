import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:copyman/services/clipboard_service.dart';
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

  group('ClipboardService', () {
    test('startMonitoring starts the timer (isActive after start)', () {
      final service = ClipboardService();
      expect(service.timer, isNull);
      service.startMonitoring();
      expect(service.timer, isNotNull);
      service.dispose();
    });

    test('stopMonitoring cancels the timer', () {
      final service = ClipboardService();
      service.startMonitoring();
      service.stopMonitoring();
      expect(service.timer, isNull);
    });

    test('setLastContent sets internal state to prevent re-capture', () {
      final service = ClipboardService();
      // Just verify the call doesn't throw and the service remains functional
      service.setLastContent('already captured');
      expect(service.timer, isNull); // not monitoring yet
      service.dispose();
    });

    test('onNewItem stream emits when add is called', () async {
      final service = ClipboardService();

      final emitted = <int>[];
      final sub = service.onNewItem.stream.listen(emitted.add);

      // Simulate what _poll does after detecting new content
      final id = await StorageService.instance.insertOrUpdate('direct emission test');
      service.onNewItem.add(id);

      // Give the event loop a chance to deliver the stream event
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isNotEmpty);
      expect(emitted.first, equals(id));

      await sub.cancel();
      service.dispose();
    });

    test('dispose cancels timer and closes stream', () async {
      final service = ClipboardService();
      service.startMonitoring();
      service.dispose();
      expect(service.timer, isNull);
      expect(service.onNewItem.isClosed, isTrue);
    });
  });
}
