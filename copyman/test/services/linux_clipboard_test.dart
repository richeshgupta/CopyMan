import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:copyman/services/linux_clipboard.dart';

ProcessResult res(int code, [Object out = '', String err = '']) =>
    ProcessResult(1, code, out, err);

void main() {
  late LinuxProcessRunner origRunner;
  late Map<String, String> origEnv;
  late List<List<String>> calls;

  void setRunner(Future<ProcessResult> Function(String, List<String>) f) {
    LinuxClipboard.runner = (exe, args, {Encoding? stdoutEncoding}) {
      calls.add([exe, ...args]);
      return f(exe, args);
    };
  }

  setUp(() {
    origRunner = LinuxClipboard.runner;
    origEnv = LinuxClipboard.environment;
    calls = [];
    LinuxClipboard.environment = {'WAYLAND_DISPLAY': 'wayland-1'};
    LinuxClipboard.resetForTest();
  });

  tearDown(() {
    LinuxClipboard.runner = origRunner;
    LinuxClipboard.environment = origEnv;
    LinuxClipboard.resetForTest();
  });

  group('isWayland', () {
    test('false without WAYLAND_DISPLAY and spawns nothing', () async {
      LinuxClipboard.environment = {};
      setRunner((_, __) async => res(0));
      expect(await LinuxClipboard.isWayland(), isFalse);
      expect(calls, isEmpty);
    });

    test('false when WAYLAND_DISPLAY is empty', () async {
      LinuxClipboard.environment = {'WAYLAND_DISPLAY': ''};
      setRunner((_, __) async => res(0));
      expect(await LinuxClipboard.isWayland(), isFalse);
      expect(calls, isEmpty);
    });

    test('false when wl-paste fails', () async {
      setRunner((_, __) async => res(127));
      expect(await LinuxClipboard.isWayland(), isFalse);
    });

    test('false when wl-paste throws', () async {
      setRunner((_, __) async => throw const ProcessException('wl-paste', []));
      expect(await LinuxClipboard.isWayland(), isFalse);
    });

    test('true on success', () async {
      setRunner((_, __) async => res(0, 'wl-paste 2.0'));
      expect(await LinuxClipboard.isWayland(), isTrue);
      expect(calls.single, ['wl-paste', '--version']);
    });

    test('cached until resetForTest', () async {
      setRunner((_, __) async => res(0));
      expect(await LinuxClipboard.isWayland(), isTrue);
      expect(await LinuxClipboard.isWayland(), isTrue);
      expect(calls.length, 1);
      LinuxClipboard.resetForTest();
      expect(await LinuxClipboard.isWayland(), isTrue);
      expect(calls.length, 2);
    });
  });

  group('readText', () {
    test('null when no text types', () async {
      setRunner((_, a) async => res(0, 'image/png\n'));
      expect(await LinuxClipboard.readText(), isNull);
      expect(calls.length, 1);
    });

    test('null when type listing fails', () async {
      setRunner((_, __) async => res(1));
      expect(await LinuxClipboard.readText(), isNull);
    });

    test('returns content untrimmed', () async {
      setRunner((_, a) async => a.contains('--list-types')
          ? res(0, 'text/plain;charset=utf-8\nUTF8_STRING\n')
          : res(0, '  hello\n world \n'));
      expect(await LinuxClipboard.readText(), '  hello\n world \n');
      expect(calls.last, ['wl-paste', '--no-newline', '--type', 'text']);
    });

    test('null on nonzero exit of read', () async {
      setRunner((_, a) async =>
          a.contains('--list-types') ? res(0, 'text/plain\n') : res(1, 'x'));
      expect(await LinuxClipboard.readText(), isNull);
    });

    test('null when runner throws', () async {
      setRunner((_, __) async => throw Exception('boom'));
      expect(await LinuxClipboard.readText(), isNull);
    });
  });

  group('readImage', () {
    test('null without image/png', () async {
      setRunner((_, __) async => res(0, 'text/plain\nimage/jpeg\n'));
      expect(await LinuxClipboard.readImage(), isNull);
      expect(calls.length, 1);
    });

    test('returns bytes', () async {
      setRunner((_, a) async => a.contains('--list-types')
          ? res(0, 'image/png\n')
          : res(0, [1, 2, 3]));
      expect(await LinuxClipboard.readImage(), [1, 2, 3]);
      expect(calls.last, ['wl-paste', '--type', 'image/png']);
    });

    test('null when empty', () async {
      setRunner((_, a) async => a.contains('--list-types')
          ? res(0, 'image/png\n')
          : res(0, <int>[]));
      expect(await LinuxClipboard.readImage(), isNull);
    });
  });

  group('sendPaste', () {
    test('wtype ctrl+v', () async {
      setRunner((_, __) async => res(0));
      await LinuxClipboard.sendPaste();
      expect(calls.last, ['wtype', '-M', 'ctrl', '-k', 'v', '-m', 'ctrl']);
      expect(calls.any((c) => c.first == 'xdotool'), isFalse);
    });

    test('wtype ctrl+shift+v', () async {
      setRunner((_, __) async => res(0));
      await LinuxClipboard.sendPaste(shift: true);
      expect(calls.last, [
        'wtype', '-M', 'ctrl', '-M', 'shift', '-k', 'v',
        '-m', 'shift', '-m', 'ctrl',
      ]);
    });

    test('falls back to xdotool when wtype fails', () async {
      setRunner((e, _) async => res(e == 'wtype' ? 1 : 0));
      await LinuxClipboard.sendPaste(shift: true);
      expect(calls.last, ['xdotool', 'key', 'ctrl+shift+v']);
    });

    test('falls back to xdotool when wtype throws', () async {
      setRunner((e, _) async {
        if (e == 'wtype') throw const ProcessException('wtype', []);
        return res(0);
      });
      await LinuxClipboard.sendPaste();
      expect(calls.last, ['xdotool', 'key', 'ctrl+v']);
    });

    test('uses xdotool when not Wayland', () async {
      LinuxClipboard.environment = {};
      setRunner((_, __) async => res(0));
      await LinuxClipboard.sendPaste();
      expect(calls, [
        ['xdotool', 'key', 'ctrl+v']
      ]);
    });
  });
}
