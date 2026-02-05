import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/clipboard_item.dart';

class StorageService {
  static const int historyLimit = 500;
  static final StorageService instance = StorageService();

  Database? _db;

  Database get db {
    if (_db == null) throw StateError('StorageService not initialised. Call init() first.');
    return _db!;
  }

  Future<void> init() async {
    final appDir = await getApplicationSupportDirectory();
    if (appDir == null) throw Exception('Cannot determine app support directory');
    await appDir.create(recursive: true);

    _db = await openDatabase(
      '${appDir.path}/copyman.db',
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clipboard_items (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        content   TEXT    NOT NULL,
        type      TEXT    NOT NULL DEFAULT 'text',
        pinned    INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_content_type
        ON clipboard_items(content, type)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_order
        ON clipboard_items(pinned DESC, updated_at DESC)
    ''');
  }

  // ── write ─────────────────────────────────────────────────────

  /// Insert or bump an existing duplicate to the top. Returns the row id.
  Future<int> insertOrUpdate(String content, {String type = 'text'}) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await db.query(
      'clipboard_items',
      where: 'content = ? AND type = ?',
      whereArgs: [content, type],
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.update(
        'clipboard_items',
        {'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
      return id;
    }

    final id = await db.insert('clipboard_items', {
      'content': content,
      'type': type,
      'pinned': 0,
      'created_at': now,
      'updated_at': now,
    });

    await _enforceLimit();
    return id;
  }

  Future<void> togglePin(int id) async {
    await db.rawUpdate(
      'UPDATE clipboard_items SET pinned = CASE WHEN pinned = 1 THEN 0 ELSE 1 END WHERE id = ?',
      [id],
    );
  }

  Future<void> deleteItem(int id) async {
    await db.delete('clipboard_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    await db.execute('DELETE FROM clipboard_items');
  }

  // ── read ──────────────────────────────────────────────────────

  Future<List<ClipboardItem>> fetchItems({
    String? search,
    int limit = 200,
    int offset = 0,
  }) async {
    final rows = await db.query(
      'clipboard_items',
      where: (search != null && search.isNotEmpty) ? 'content LIKE ?' : null,
      whereArgs: (search != null && search.isNotEmpty) ? ['%$search%'] : null,
      orderBy: 'pinned DESC, updated_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(ClipboardItem.fromMap).toList();
  }

  // ── housekeeping ──────────────────────────────────────────────

  /// Remove oldest unpinned rows beyond the limit.
  Future<void> _enforceLimit() async {
    await db.rawDelete('''
      DELETE FROM clipboard_items
      WHERE id IN (
        SELECT id FROM clipboard_items
        WHERE pinned = 0
        ORDER BY updated_at DESC
        LIMIT -1 OFFSET ?
      )
    ''', [historyLimit]);
  }

  Future<void> close() async {
    await _db?.close();
  }
}
