import 'dart:io';

typedef ProcessRunner = Future<ProcessResult> Function(
    String executable, List<String> arguments);

class AppDetectionService {
  /// Get the name of the currently active/foreground window application.
  /// Returns null if unable to detect or on unsupported platform.
  static Future<String?> getForegroundApp({
    ProcessRunner runner = Process.run,
  }) async {
    if (Platform.isLinux) {
      return _getLinuxForegroundApp(runner);
    }
    if (Platform.isMacOS) {
      return _getMacOSForegroundApp(runner);
    }
    if (Platform.isWindows) {
      return _getWindowsForegroundApp(runner);
    }
    return null;
  }

  static Future<String?> _getWindowsForegroundApp(ProcessRunner runner) async {
    try {
      final result = await runner('powershell', [
        '-NoProfile',
        '-Command',
        '(Get-Process | Where-Object {\$_.MainWindowHandle -eq '
            '(Add-Type -MemberDefinition \'[DllImport("user32.dll")] '
            'public static extern IntPtr GetForegroundWindow();\' '
            '-Name Win32 -Namespace Temp -PassThru)::GetForegroundWindow()}'
            ').ProcessName',
      ]);
      if (result.exitCode != 0) return null;
      final name = (result.stdout as String).trim();
      return name.isNotEmpty ? name : null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _getMacOSForegroundApp(ProcessRunner runner) async {
    try {
      final result = await runner('osascript', [
        '-e',
        'tell application "System Events" to get name of first application process whose frontmost is true',
      ]);
      if (result.exitCode != 0) return null;
      final name = (result.stdout as String).trim();
      return name.isNotEmpty ? name : null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _getLinuxForegroundApp(ProcessRunner runner) async {
    try {
      // Get the active window ID
      final widResult = await runner('xdotool', ['getactivewindow']);
      if (widResult.exitCode != 0) return null;
      final windowId = (widResult.stdout as String).trim();

      // Get the WM_CLASS property
      final propResult = await runner(
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
