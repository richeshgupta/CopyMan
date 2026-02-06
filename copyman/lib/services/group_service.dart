import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/clipboard_item.dart';
import '../models/group.dart';
import 'storage_service.dart';

class GroupService {
  static final GroupService instance = GroupService();

  Database get db => StorageService.instance.db;

  // ── READ ──────────────────────────────────────────────────────

  /// Fetch all groups, sorted by name
  Future<List<Group>> fetchAllGroups() async {
    final rows = await db.query(
      'groups',
      orderBy: 'name ASC',
    );
    return rows.map(Group.fromMap).toList();
  }

  /// Fetch a single group by ID
  Future<Group?> fetchGroupById(int id) async {
    final rows = await db.query(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Group.fromMap(rows.first);
  }

  /// Get the default "Uncategorized" group
  Future<Group?> getUncategorizedGroup() async {
    return fetchGroupById(1);
  }

  // ── WRITE ─────────────────────────────────────────────────────

  /// Create a new group
  Future<int> createGroup(String name, {String color = '#4CAF50'}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return await db.insert('groups', {
      'name': name,
      'color': color,
      'created_at': now,
      'updated_at': now,
    });
  }

  /// Update an existing group
  Future<void> updateGroup(int id, {String? name, String? color}) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    if (name != null) updates['name'] = name;
    if (color != null) updates['color'] = color;

    await db.update(
      'groups',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a group. Optionally move items to another group (default: null = Uncategorized)
  Future<void> deleteGroup(int id, {int? moveToGroupId}) async {
    // Cannot delete the Uncategorized group
    if (id == 1) {
      throw ArgumentError('Cannot delete the Uncategorized group');
    }

    // Move items to the target group (or null for Uncategorized)
    await db.update(
      'clipboard_items',
      {'group_id': moveToGroupId ?? 1},
      where: 'group_id = ?',
      whereArgs: [id],
    );

    // Delete the group
    await db.delete('groups', where: 'id = ?', whereArgs: [id]);
  }

  /// Move an item to a different group
  Future<void> moveItemToGroup(int itemId, int? groupId) async {
    await db.update(
      'clipboard_items',
      {'group_id': groupId ?? 1},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // ── CONVENIENCE ───────────────────────────────────────────────

  /// Fetch all items in a specific group
  Future<List<ClipboardItem>> fetchItemsInGroup(int groupId) async {
    final rows = await db.query(
      'clipboard_items',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'pinned DESC, updated_at DESC',
    );
    return rows.map(ClipboardItem.fromMap).toList();
  }

  /// Get the count of items in a group
  Future<int> getGroupItemCount(int groupId) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM clipboard_items WHERE group_id = ?',
      [groupId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get all groups with their item counts (for display in sidebar)
  Future<List<Map<String, dynamic>>> getGroupsWithCounts() async {
    final groups = await fetchAllGroups();
    final result = <Map<String, dynamic>>[];

    for (final group in groups) {
      final count = await getGroupItemCount(group.id);
      result.add({
        'group': group,
        'count': count,
      });
    }

    return result;
  }
}
