import 'package:flutter/material.dart';

import '../models/clipboard_item.dart';

class ClipboardItemTile extends StatelessWidget {
  final ClipboardItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final VoidCallback onPasteAsPlain;
  final List<int> matchIndices;

  const ClipboardItemTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
    required this.onPin,
    required this.onDelete,
    required this.onPasteAsPlain,
    this.matchIndices = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onSecondaryTapDown: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : null,
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: item.pinned
                ? BorderSide(color: theme.colorScheme.primary, width: 3)
                : BorderSide.none,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.pinned)
                    Padding(
                      padding: const EdgeInsets.only(right: 6, top: 1),
                      child: Icon(
                        Icons.push_pin,
                        size: 13,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  Expanded(
                    child: RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: _buildHighlightedText(theme),
                    ),
                  ),
                  // TODO: Image thumbnail rendering if item.contentBytes != null
                ],
              ),
              const SizedBox(height: 3),
              Text(
                item.relativeTime,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextSpan _buildHighlightedText(ThemeData theme) {
    final matchSet = matchIndices.toSet();
    final spans = <TextSpan>[];

    for (int i = 0; i < item.content.length; i++) {
      final char = item.content[i];
      final isMatch = matchSet.contains(i);

      spans.add(
        TextSpan(
          text: char,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface,
            fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
            backgroundColor: isMatch
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : null,
            height: 1.4,
          ),
        ),
      );
    }

    return TextSpan(children: spans);
  }

  Future<void> _showContextMenu(BuildContext context, Offset position) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 140, position.dy + 110),
      items: [
        PopupMenuItem<String>(
          value: 'pin',
          child: Row(
            children: [
              Icon(
                item.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 16,
              ),
              const SizedBox(width: 10),
              Text(item.pinned ? 'Unpin' : 'Pin'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'copy',
          child: const Row(
            children: [
              Icon(Icons.copy_outlined, size: 16),
              SizedBox(width: 10),
              Text('Copy'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'paste_plain',
          child: const Row(
            children: [
              Icon(Icons.text_fields, size: 16),
              SizedBox(width: 10),
              Text('Paste as Plain'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: const Row(
            children: [
              Icon(Icons.delete_outline, size: 16),
              SizedBox(width: 10),
              Text('Delete'),
            ],
          ),
        ),
      ],
    );

    switch (result) {
      case 'pin':
        onPin();
        break;
      case 'copy':
        onTap();
        break;
      case 'paste_plain':
        onPasteAsPlain();
        break;
      case 'delete':
        onDelete();
        break;
    }
  }
}
