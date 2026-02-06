import 'package:flutter/material.dart';

import '../models/group.dart';
import 'groups_panel.dart';

class GroupFilterChips extends StatelessWidget {
  final List<Group> groups;
  final int? selectedGroupId;
  final ValueChanged<int?> onGroupSelected;
  final VoidCallback onNewGroup;
  final Function(Group) onGroupRenamed;
  final Function(Group) onGroupDeleted;
  final Function(Group, String) onGroupColorChanged;

  const GroupFilterChips({
    super.key,
    required this.groups,
    required this.selectedGroupId,
    required this.onGroupSelected,
    required this.onNewGroup,
    required this.onGroupRenamed,
    required this.onGroupDeleted,
    required this.onGroupColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ChoiceChip(
              label: const Text('All'),
              labelStyle: TextStyle(fontSize: 11, color: selectedGroupId == null
                  ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface),
              selected: selectedGroupId == null,
              selectedColor: theme.colorScheme.primary,
              onSelected: (_) => onGroupSelected(null),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          // Group chips
          ...groups.where((g) => g.id != 1 || groups.length == 1).map((group) {
            final isSelected = selectedGroupId == group.id;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onSecondaryTapDown: (details) {
                  if (group.id == 1) return;
                  _showChipContextMenu(context, group, details.globalPosition);
                },
                child: ChoiceChip(
                  avatar: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: group.toFlutterColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  label: Text(group.name),
                  labelStyle: TextStyle(fontSize: 11, color: isSelected
                      ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primary,
                  onSelected: (_) => onGroupSelected(group.id),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            );
          }),
          // Add group chip
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ActionChip(
              label: const Icon(Icons.add, size: 14),
              onPressed: onNewGroup,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showChipContextMenu(
    BuildContext context,
    Group group,
    Offset position,
  ) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx, position.dy, position.dx + 100, position.dy + 80,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'rename',
          child: Row(children: [
            Icon(Icons.edit_outlined, size: 16),
            SizedBox(width: 10),
            Text('Rename'),
          ]),
        ),
        const PopupMenuItem<String>(
          value: 'color',
          child: Row(children: [
            Icon(Icons.palette_outlined, size: 16),
            SizedBox(width: 10),
            Text('Change color'),
          ]),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline, size: 16),
            SizedBox(width: 10),
            Text('Delete'),
          ]),
        ),
      ],
    );

    if (!context.mounted) return;

    switch (result) {
      case 'rename':
        _showRenameDialog(context, group);
        break;
      case 'color':
        _showColorPicker(context, group);
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
      onGroupRenamed(group.copyWith(name: newName));
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
      onGroupDeleted(group);
    }
  }

  Future<void> _showColorPicker(BuildContext context, Group group) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick a color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kGroupColorPresets.map((hex) {
            final color = Color(int.parse(hex.replaceFirst('#', '0xff')));
            final isSelected = hex.toUpperCase() == group.color.toUpperCase();
            return GestureDetector(
              onTap: () => Navigator.pop(ctx, hex),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4)]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (picked != null) {
      onGroupColorChanged(group, picked);
    }
  }
}
