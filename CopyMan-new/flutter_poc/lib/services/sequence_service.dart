import '../models/clipboard_item.dart';
import '../models/sequence_session.dart';

class SequenceService {
  SequenceSession? _currentSession;

  /// Check if a sequence is currently active
  bool get isActive => _currentSession != null;

  /// Get the current sequence session (null if not active)
  SequenceSession? get session => _currentSession;

  /// Start a new sequence with the given items
  /// Requires at least 2 items
  void startSequence(List<ClipboardItem> items) {
    if (items.length < 2) {
      throw ArgumentError('Need at least 2 items to start a sequence');
    }
    _currentSession = SequenceSession(items: items, currentIndex: 0);
  }

  /// Advance to the next item in the sequence
  /// Does nothing if already at the end
  void advance() {
    if (_currentSession != null) {
      _currentSession!.advance();
    }
  }

  /// Cancel the current sequence
  void cancel() {
    _currentSession = null;
  }

  /// Get the current item in the sequence (null if not active)
  ClipboardItem? getCurrentItem() => _currentSession?.currentItem;

  /// Check if there are more items to advance to
  bool get hasNext => _currentSession?.hasNext ?? false;

  /// Check if the sequence is complete
  bool get isComplete => _currentSession?.isComplete ?? false;

  /// Get the progress string (e.g., "1/3")
  String get progress => _currentSession?.progress ?? '';
}
