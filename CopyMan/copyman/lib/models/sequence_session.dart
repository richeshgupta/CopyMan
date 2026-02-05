import 'clipboard_item.dart';

class SequenceSession {
  final List<ClipboardItem> items;
  int currentIndex; // Current item index (0 = first)

  SequenceSession({
    required this.items,
    this.currentIndex = 0,
  }) : assert(items.isNotEmpty, 'SequenceSession requires at least one item');

  /// Get current item in sequence
  ClipboardItem get currentItem => items[currentIndex];

  /// Check if there are more items to advance to
  bool get hasNext => currentIndex < items.length - 1;

  /// Check if sequence is complete (past the last item)
  bool get isComplete => currentIndex >= items.length;

  /// Advance to the next item
  void advance() {
    if (hasNext) {
      currentIndex++;
    }
  }

  /// Get progress string (e.g., "1/3", "3/3")
  String get progress => '${currentIndex + 1}/${items.length}';

  /// Total number of items in sequence
  int get length => items.length;
}
