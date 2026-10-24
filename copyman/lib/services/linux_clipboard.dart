import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

typedef LinuxProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  Encoding? stdoutEncoding,
});

/// Wayland-native clipboard access via wl-clipboard and wtype.
///
/// CopyMan runs under XWayland (GDK_BACKEND=x11), where copies made by
/// native Wayland clients are not visible to GTK or xclip. On a Wayland
/// session these helpers read the real compositor clipboard instead.
class LinuxClipboard {
  /// Injectable process runner for testing.
  static LinuxProcessRunner runner = _defaultRunner;

  /// Injectable environment for testing.
  static Map<String, String> environment = Platform.environment;

  static bool? _waylandAvailable;

  static Future<ProcessResult> _defaultRunner(
    String executable,
    List<String> arguments, {
    Encoding? stdoutEncoding = systemEncoding,
  }) =>
      Process.run(executable, arguments, stdoutEncoding: stdoutEncoding);

  /// True on a Wayland session where `wl-paste` is installed.
  static Future<bool> isWayland() async {
    final cached = _waylandAvailable;
    if (cached != null) return cached;
    var available = false;
    if ((environment['WAYLAND_DISPLAY'] ?? '').isNotEmpty) {
      try {
        final r = await runner('wl-paste', ['--version']);
        available = r.exitCode == 0;
      } catch (_) {}
    }
    return _waylandAvailable = available;
  }

  /// Clears the cached [isWayland] result (for tests).
  static void resetForTest() {
    _waylandAvailable = null;
    _typesInFlight = null;
    _typesAt = null;
  }

  static const _typesTtl = Duration(milliseconds: 250);
  static Future<List<String>>? _typesInFlight;
  static DateTime? _typesAt;

  /// MIME types currently offered on the clipboard, or empty if none.
  ///
  /// The image and text readers run back to back in each poll, so the listing
  /// is shared for a short time instead of spawning wl-paste twice.
  static Future<List<String>> _types() {
    final at = _typesAt;
    final inFlight = _typesInFlight;
    if (inFlight != null &&
        at != null &&
        DateTime.now().difference(at) < _typesTtl) {
      return inFlight;
    }
    _typesAt = DateTime.now();
    return _typesInFlight = _listTypes();
  }

  static Future<List<String>> _listTypes() async {
    final r = await runner('wl-paste', ['--list-types']);
    if (r.exitCode != 0) return const [];
    return (r.stdout as String)
        .split('\n')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Plain text on the clipboard, or null when there is none.
  static Future<String?> readText() async {
    try {
      final types = await _types();
      if (!types.any((t) => t == 'text/plain' || t.startsWith('text/plain;') ||
          t == 'UTF8_STRING' || t == 'STRING')) {
        return null;
      }
      final r = await runner('wl-paste', ['--no-newline', '--type', 'text']);
      if (r.exitCode != 0) return null;
      return r.stdout as String;
    } catch (_) {
      return null;
    }
  }

  /// PNG image bytes on the clipboard, or null when there are none.
  static Future<Uint8List?> readImage() async {
    try {
      if (!(await _types()).contains('image/png')) return null;
      final r = await runner(
        'wl-paste',
        ['--type', 'image/png'],
        stdoutEncoding: null,
      );
      if (r.exitCode != 0) return null;
      final out = r.stdout;
      if (out is List<int> && out.isNotEmpty) return Uint8List.fromList(out);
    } catch (_) {}
    return null;
  }

  /// Sends Ctrl+V (or Ctrl+Shift+V) to the focused window.
  ///
  /// Uses `wtype` on Wayland so native windows receive the keystroke, and
  /// falls back to `xdotool` (XWayland windows, or X11 sessions).
  static Future<void> sendPaste({bool shift = false}) async {
    if (await isWayland()) {
      try {
        final r = await runner('wtype', [
          '-M', 'ctrl',
          if (shift) ...['-M', 'shift'],
          '-k', 'v',
          if (shift) ...['-m', 'shift'],
          '-m', 'ctrl',
        ]);
        if (r.exitCode == 0) return;
      } catch (_) {}
    }
    await runner('xdotool', ['key', shift ? 'ctrl+shift+v' : 'ctrl+v']);
  }
}
