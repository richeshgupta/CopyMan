import 'package:flutter/material.dart';

import '../models/group.dart';

class GroupsPanel extends StatefulWidget {
  final List<Group> groups;
  final int? selectedGroupId;
  final ValueChanged<int?> onGroupSelected;
  final VoidCallback onNewGroup;
  final Function(Group) onGroupRenamed;
  final Function(Group) onGroupDeleted;
  final Map<int, int> groupCounts; // group id -> item count

  const GroupsPanel({
    required this.groups,
    required this.selectedGroupId,
    required this.onGroupSelected,
    required this.onNewGroup,
    required this.onGroupRenamed,
    required this.onGroupDeleted,
    required this.groupCounts,
  });

  @override
  State<GroupsPanel> createState() => _GroupsPanelState();
}

class _GroupsPanelState extends State<GroupsPanel> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          // ── header ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Groups',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onNewGroup,
                  tooltip: 'New group',
                ),
              ],
            ),
          ),

          // ── groups list ───────────────────────────────────────
          Expanded(
            child: ListView.builder(
              itemCount: widget.groups.length,
              itemBuilder: (ctx, i) {
                final group = widget.groups[i];
                final count = widget.groupCounts[group.id] ?? 0;
                final isSelected = widget.selectedGroupId == group.id;

                return GestureDetector(
                  onTap: () => widget.onGroupSelected(group.id),
                  onSecondaryTapDown: (details) =>
                      _showGroupContextMenu(context, group, details.globalPosition),
                  child: Container(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : null,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        // Checkbox / icon
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: theme.colorScheme.primary,
                          )
                        else
                          Icon(
                            Icons.circle_outlined,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
                        const SizedBox(width: 10),

                        // Group name and count
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface,
                                  fontWeight:
                                      isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              Text(
                                '($count item${count != 1 ? 's' : ''})',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── "All Items" option at bottom ─────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: GestureDetector(
              onTap: () => widget.onGroupSelected(null),
              child: Container(
                color: widget.selectedGroupId == null
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : null,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    if (widget.selectedGroupId == null)
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: theme.colorScheme.primary,
                      )
                    else
                      Icon(
                        Icons.circle_outlined,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      'All Items',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                        fontWeight: widget.selectedGroupId == null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showGroupContextMenu(
    BuildContext context,
    Group group,
    Offset position,
  ) async {
    // Cannot delete Uncategorized group
    if (group.id == 1) return;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 100,
        position.dy + 80,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'rename',
          child: const Row(
            children: [
              Icon(Icons.edit_outlined, size: 16),
              SizedBox(width: 10),
              Text('Rename'),
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
      case 'rename':
        _showRenameDialog(context, group);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, group);
        break;
    }
  }

  Future<void> _showRenameDialog(BuildContext context, Group group) async {
    final controller = TextEditingController(text: group.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Group'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Group name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      widget.onGroupRenamed(group.copyWith(name: newName));
    }
    controller.dispose();
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context, Group group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group?'),
        content: Text(
          'Delete "${group.name}"? Items will be moved to Uncategorized.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      widget.onGroupDeleted(group);
    }
  }
}
