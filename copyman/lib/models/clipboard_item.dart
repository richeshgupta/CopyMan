import 'dart:typed_data';

class ClipboardItem {
  final int id;
  final String content;
  final String type; // 'text'
  final bool pinned;
  final int createdAt; // Unix timestamp ms
  final int updatedAt; // Unix timestamp ms
  final Uint8List? contentBytes; // Future: for image/binary content
  final String? contentHash; // Future: for deduplication
  final int? groupId; // null = uncategorized; FK to groups.id

  ClipboardItem({
    required this.id,
    required this.content,
    this.type = 'text',
    this.pinned = false,
    required this.createdAt,
    required this.updatedAt,
    this.contentBytes,
    this.contentHash,
    this.groupId,
  });

  factory ClipboardItem.fromMap(Map<String, dynamic> map) {
    return ClipboardItem(
      id: map['id'] as int,
      content: map['content'] as String,
      type: map['type'] as String,
      pinned: (map['pinned'] as int) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      contentBytes: map['content_bytes'] as Uint8List?,
      contentHash: map['content_hash'] as String?,
      groupId: map['group_id'] as int?,
    );
  }

  String get relativeTime {
    final diff = DateTime.now().millisecondsSinceEpoch - updatedAt;
    if (diff < 60_000) return 'just now';
    if (diff < 3_600_000) return '${diff ~/ 60_000}m ago';
    if (diff < 86_400_000) return '${diff ~/ 3_600_000}h ago';
    return '${diff ~/ 86_400_000}d ago';
  }
}
