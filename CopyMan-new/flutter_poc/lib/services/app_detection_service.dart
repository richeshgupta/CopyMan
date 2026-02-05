import 'dart:io';

class AppDetectionService {
  /// Get the name of the currently active/foreground window application.
  /// Returns null if unable to detect or on unsupported platform.
  static Future<String?> getForegroundApp() async {
    if (Platform.isLinux) {
      return _getLinuxForegroundApp();
    }
    // Windows/macOS: TODO
    return null;
  }

  static Future<String?> _getLinuxForegroundApp() async {
    try {
      // Get the active window ID
      final widResult = await Process.run('xdotool', ['getactivewindow']);
      if (widResult.exitCode != 0) return null;
      final windowId = (widResult.stdout as String).trim();

      // Get the WM_CLASS property
      final propResult = await Process.run(
        'xprop',
        ['-id', windowId, 'WM_CLASS'],
      );
      if (propResult.exitCode != 0) return null;

      // Parse output: WM_CLASS(STRING) = "instance", "class"
      // Extract the second quoted value (class name)
      final output = propResult.stdout as String;
      final match = RegExp(r'"([^"]+)",\s*"([^"]+)"').firstMatch(output);
      if (match != null && match.groupCount >= 2) {
        return match.group(2); // Return the class name
      }
      return null;
    } catch (_) {
      // xdotool/xprop not available
      return null;
    }
  }
}
