import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../utils/sensitive_detector.dart';
import 'app_detection_service.dart';
import 'storage_service.dart';

typedef ImageReader = Future<Uint8List?> Function();

class ClipboardService {
  static const Duration pollInterval = Duration(milliseconds: 500);

  Timer? _timer;
  String? _lastContent;
  String? _lastImageHash;

  /// Injectable image reader for testing.
  ImageReader? imageReaderOverride;

  /// Emits the row-id whenever a new (or bumped) item lands in the DB.
  final StreamController<int> onNewItem = StreamController<int>.broadcast();

  void startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => _poll());
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    try {
      // Check if the foreground app is excluded
      try {
        final appName = await AppDetectionService.getForegroundApp();
        if (appName != null) {
          final isExcluded =
              await StorageService.instance.isAppExcluded(appName);
          if (isExcluded) return;
        }
      } catch (_) {}

      // Try image capture FIRST — some apps put both text (file path) and
      // image data on the clipboard; we prefer the image.
      final skipImages =
          await StorageService.instance.getSetting('skip_images');
      if (skipImages != 'true') {
        final imageBytes = imageReaderOverride != null
            ? await imageReaderOverride!()
            : await _readClipboardImage();
        if (imageBytes != null && imageBytes.isNotEmpty) {
          // Check size limit
          final skipLarge =
              await StorageService.instance.getSetting('skip_large_images');
          if (skipLarge == 'true') {
            final maxStr =
                await StorageService.instance.getSetting('max_image_size_mb');
            final maxBytes =
                ((double.tryParse(maxStr ?? '') ?? 5.0) * 1024 * 1024).round();
            if (imageBytes.length > maxBytes) return;
          }

          final hash = sha256.convert(imageBytes).toString();
          if (hash != _lastImageHash) {
            _lastImageHash = hash;
            _lastContent = null; // Image changed, reset text tracking
            final id = await StorageService.instance.insertOrUpdate(
              '[Image ${_formatBytes(imageBytes.length)}]',
              type: 'image',
              contentBytes: imageBytes,
              contentHash: hash,
            );
            onNewItem.add(id);
          }
          return;
        }
      }

      // Then try text
      final data = await Clipboard.getData('text/plain');
      final text = data?.text?.trim();
      if (text != null && text.isNotEmpty && text != _lastContent) {
        // Check if the text is an image file path (e.g. copied from file manager)
        final imageBytes = await _tryReadImageFromPath(text);
        if (imageBytes != null && skipImages != 'true') {
          _lastContent = text;
          final hash = sha256.convert(imageBytes).toString();
          if (hash != _lastImageHash) {
            _lastImageHash = hash;
            final id = await StorageService.instance.insertOrUpdate(
              '[Image ${_formatBytes(imageBytes.length)}]',
              type: 'image',
              contentBytes: imageBytes,
              contentHash: hash,
            );
            onNewItem.add(id);
          }
          return;
        }

        _lastContent = text;
        _lastImageHash = null; // Text changed, reset image tracking

        // Skip sensitive content if setting is enabled
        final autoExcl = await StorageService.instance
            .getSetting('auto_exclude_sensitive');
        if (autoExcl == 'true' && SensitiveDetector.isSensitive(text)) return;

        final id = await StorageService.instance.insertOrUpdate(text);
        onNewItem.add(id);
      }
    } catch (_) {
      // Clipboard can be empty or contain unsupported data — ignore.
    }
  }

  /// Read image data from the system clipboard using platform tools.
  /// Image file extensions we recognise.
  static const _imageExtensions = {'.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.tiff', '.tif'};

  /// If [text] looks like a local image file path (or file:// URI), read it.
  static Future<Uint8List?> _tryReadImageFromPath(String text) async {
    try {
      String path = text;
      // Handle file:// URIs (from file managers)
      if (path.startsWith('file://')) {
        path = Uri.decodeFull(path.replaceFirst('file://', ''));
      }
      // Handle multiple URIs (file managers may copy newline-separated list)
      if (path.contains('\n')) {
        path = path.split('\n').first.trim();
        if (path.startsWith('file://')) {
          path = Uri.decodeFull(path.replaceFirst('file://', ''));
        }
      }
      // Must look like an absolute path to an image file
      if (!path.startsWith('/')) return null;
      final ext = path.contains('.') ? '.${path.split('.').last.toLowerCase()}' : '';
      if (!_imageExtensions.contains(ext)) return null;
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _readClipboardImage() async {
    try {
      if (Platform.isLinux) {
        return _readLinuxClipboardImage();
      } else if (Platform.isMacOS) {
        return _readMacOSClipboardImage();
      }
    } catch (_) {}
    return null;
  }

  static Future<Uint8List?> _readLinuxClipboardImage() async {
    // Check if clipboard has image target
    final targets = await Process.run(
      'xclip',
      ['-selection', 'clipboard', '-t', 'TARGETS', '-o'],
    );
    if (targets.exitCode != 0) return null;
    final targetList = (targets.stdout as String);
    if (!targetList.contains('image/png')) return null;

    final result = await Process.run(
      'xclip',
      ['-selection', 'clipboard', '-t', 'image/png', '-o'],
      stdoutEncoding: null, // raw bytes
    );
    if (result.exitCode != 0) return null;
    final bytes = result.stdout;
    if (bytes is List<int> && bytes.isNotEmpty) {
      return Uint8List.fromList(bytes);
    }
    return null;
  }

  static Future<Uint8List?> _readMacOSClipboardImage() async {
    // Check if clipboard has public.png
    final check = await Process.run('osascript', [
      '-e',
      'try\n'
          'set theData to (the clipboard as «class PNGf»)\n'
          'return "has_image"\n'
          'on error\n'
          'return "no_image"\n'
          'end try',
    ]);
    if (check.exitCode != 0 ||
        !(check.stdout as String).contains('has_image')) {
      return null;
    }

    // Write clipboard image to temp file and read it
    final tmpFile = '${Directory.systemTemp.path}/copyman_clip.png';
    final result = await Process.run('osascript', [
      '-e',
      'set theFile to POSIX file "$tmpFile"\n'
          'try\n'
          'set theData to (the clipboard as «class PNGf»)\n'
          'set fileRef to open for access theFile with write permission\n'
          'write theData to fileRef\n'
          'close access fileRef\n'
          'return "ok"\n'
          'on error\n'
          'return "fail"\n'
          'end try',
    ]);
    if (result.exitCode != 0 ||
        !(result.stdout as String).contains('ok')) {
      return null;
    }

    final file = File(tmpFile);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      await file.delete();
      return bytes.isNotEmpty ? bytes : null;
    }
    return null;
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Call before programmatically writing to the clipboard so the next poll
  /// doesn't re-capture what we just pasted.
  void setLastContent(String content) {
    _lastContent = content;
  }

  /// Set last image hash to prevent re-capture.
  void setLastImageHash(String hash) {
    _lastImageHash = hash;
  }

  /// For testing: expose the internal timer.
  Timer? get timer => _timer;

  /// For testing: trigger a poll manually.
  Future<void> pollForTest() => _poll();

  void dispose() {
    stopMonitoring();
    onNewItem.close();
  }
}
