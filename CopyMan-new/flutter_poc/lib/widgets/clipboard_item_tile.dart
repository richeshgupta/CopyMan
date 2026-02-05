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
  final bool isMultiSelectMode;
  final bool isCheckboxChecked;
  final ValueChanged<bool>? onCheckboxChanged;
  final Function(ClipboardItem)? onMoveToGroup;

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
    this.isMultiSelectMode = false,
    this.isCheckboxChecked = false,
    this.onCheckboxChanged,
    this.onMoveToGroup,
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
                  // Multi-select checkbox (if in multi-select mode)
                  if (isMultiSelectMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 1),
                      child: GestureDetector(
                        onTap: () => onCheckboxChanged?.call(!isCheckboxChecked),
                        child: Icon(
                          isCheckboxChecked
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 16,
                          color: isCheckboxChecked
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                        ),
                      ),
                    ),

                  // Pin indicator
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
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 160, position.dy + 130),
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
          value: 'move_to_group',
          child: const Row(
            children: [
              Icon(Icons.folder_open_outlined, size: 16),
              SizedBox(width: 10),
              Text('Move to Group'),
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
      case 'move_to_group':
        onMoveToGroup?.call(item);
        break;
      case 'delete':
        onDelete();
        break;
    }
  }
}
