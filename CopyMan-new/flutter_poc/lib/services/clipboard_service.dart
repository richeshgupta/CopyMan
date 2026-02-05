import 'dart:async';

import 'package:flutter/services.dart';

import 'app_detection_service.dart';
import 'storage_service.dart';

class ClipboardService {
  static const Duration pollInterval = Duration(milliseconds: 500);

  Timer? _timer;
  String? _lastContent;

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
      final data = await Clipboard.getData('text/plain');
      final text = data?.text;
      if (text != null && text.isNotEmpty && text != _lastContent) {
        _lastContent = text;

        // Check if the foreground app is excluded
        try {
          final appName = await AppDetectionService.getForegroundApp();
          if (appName != null) {
            final isExcluded = await StorageService.instance.isAppExcluded(appName);
            if (isExcluded) return; // Skip capturing from excluded apps
          }
        } catch (_) {
          // If app detection fails, proceed with capture
        }

        final id = await StorageService.instance.insertOrUpdate(text);
        onNewItem.add(id);
      }

      // TODO: Image capture via Clipboard.getData('image/png'), hash with SHA256,
      // store as (contentBytes, contentHash) in insertOrUpdate. Requires xclip polling
      // on Linux or equivalent per-platform.
    } catch (_) {
      // Clipboard can be empty or contain only non-text data — ignore.
    }
  }

  /// Call before programmatically writing to the clipboard so the next poll
  /// doesn't re-capture what we just pasted.
  void setLastContent(String content) {
    _lastContent = content;
  }

  void dispose() {
    stopMonitoring();
    onNewItem.close();
  }
}
