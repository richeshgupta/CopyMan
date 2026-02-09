import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/clipboard_item.dart';

class StorageService {
  static final StorageService instance = StorageService();

  Database? _db;
  late int _cachedHistoryLimit;

  Database get db {
    final database = _db;
    if (database == null) throw StateError('StorageService not initialised. Call init() first.');
    return database;
  }

  Future<void> init() async {
    final appDir = await getApplicationSupportDirectory();
    // ignore: unnecessary_null_comparison, dead_code
    if (appDir == null) {
      throw Exception('Cannot determine app support directory');
    }
    await appDir.create(recursive: true);

    _db = await openDatabase(
      '${appDir.path}/copyman.db',
      version: 3,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );

    _cachedHistoryLimit = await getHistoryLimit();
  }

  /// Initialize with a custom path (use ':memory:' for tests).
  Future<void> initForTest(String path) async {
    _db = await openDatabase(
      path,
      version: 3,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
    _cachedHistoryLimit = await getHistoryLimit();
  }

  Future<void> _createTables(Database db, int version) async {
    // Create groups table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS groups (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        name      TEXT UNIQUE NOT NULL,
        color     TEXT DEFAULT '#4CAF50',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create default "Uncategorized" group
    await db.insert(
      'groups',
      {
        'id': 1,
        'name': 'Uncategorized',
        'color': '#9E9E9E',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS clipboard_items (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        content        TEXT    NOT NULL,
        type           TEXT    NOT NULL DEFAULT 'text',
        pinned         INTEGER NOT NULL DEFAULT 0,
        created_at     INTEGER NOT NULL,
        updated_at     INTEGER NOT NULL,
        content_bytes  BLOB,
        content_hash   TEXT,
        group_id       INTEGER DEFAULT 1 REFERENCES groups(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_order
        ON clipboard_items(pinned DESC, updated_at DESC)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_group_id
        ON clipboard_items(group_id)
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_exclusions (
        app_name TEXT PRIMARY KEY,
        blocked  INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    // Pre-seed exclusions
    await db.insert('app_exclusions', {'app_name': '1Password', 'blocked': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('app_exclusions', {'app_name': 'Bitwarden', 'blocked': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('app_exclusions', {'app_name': 'LastPass', 'blocked': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('app_exclusions', {'app_name': 'KeePass', 'blocked': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('app_exclusions', {'app_name': 'KeePassXC', 'blocked': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('app_exclusions', {'app_name': 'Enpass', 'blocked': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('app_exclusions', {'app_name': 'Dashlane', 'blocked': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('app_exclusions', {'app_name': 'Keeper', 'blocked': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: Add new columns for image support
      await db.execute('ALTER TABLE clipboard_items ADD COLUMN content_bytes BLOB');
      await db.execute('ALTER TABLE clipboard_items ADD COLUMN content_hash TEXT');
      // Remove old unique index that would prevent image deduplication
      await db.execute('DROP INDEX IF EXISTS idx_content_type');
      // Create new tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_exclusions (
          app_name TEXT PRIMARY KEY,
          blocked  INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key   TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      // Pre-seed exclusions
      await db.insert('app_exclusions', {'app_name': '1Password', 'blocked': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('app_exclusions', {'app_name': 'Bitwarden', 'blocked': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('app_exclusions', {'app_name': 'LastPass', 'blocked': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('app_exclusions', {'app_name': 'KeePass', 'blocked': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('app_exclusions', {'app_name': 'KeePassXC', 'blocked': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('app_exclusions', {'app_name': 'Enpass', 'blocked': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('app_exclusions', {'app_name': 'Dashlane', 'blocked': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('app_exclusions', {'app_name': 'Keeper', 'blocked': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    if (oldVersion < 3) {
      // v2 → v3: Add groups table and group_id column
      await db.execute('''
        CREATE TABLE IF NOT EXISTS groups (
          id        INTEGER PRIMARY KEY AUTOINCREMENT,
          name      TEXT UNIQUE NOT NULL,
          color     TEXT DEFAULT '#4CAF50',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Create default "Uncategorized" group
      await db.insert(
        'groups',
        {
          'id': 1,
          'name': 'Uncategorized',
          'color': '#9E9E9E',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      // Add group_id column to existing clipboard_items table
      await db.execute('ALTER TABLE clipboard_items ADD COLUMN group_id INTEGER DEFAULT 1');

      // Create index for fast group filtering
      await db.execute('CREATE INDEX IF NOT EXISTS idx_group_id ON clipboard_items(group_id)');
    }
  }

  // ── write ─────────────────────────────────────────────────────

  /// Insert or bump an existing duplicate to the top. Returns the row id.
  Future<int> insertOrUpdate(
    String content, {
    String type = 'text',
    Uint8List? contentBytes,
    String? contentHash,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // For images, deduplicate by hash; for text, by content+type.
    List<Map<String, dynamic>> existing;
    if (type == 'image' && contentHash != null) {
      existing = await db.query(
        'clipboard_items',
        where: 'content_hash = ? AND type = ?',
        whereArgs: [contentHash, type],
      );
    } else {
      existing = await db.query(
        'clipboard_items',
        where: 'content = ? AND type = ?',
        whereArgs: [content, type],
      );
    }

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
      'content_bytes': contentBytes,
      'content_hash': contentHash,
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

  /// Remove oldest unpinned rows beyond the limit, and TTL-expired items.
  Future<void> _enforceLimit() async {
    await clearExpiredItems();
    await db.rawDelete('''
      DELETE FROM clipboard_items
      WHERE id IN (
        SELECT id FROM clipboard_items
        WHERE pinned = 0
        ORDER BY updated_at DESC
        LIMIT -1 OFFSET ?
      )
    ''', [_cachedHistoryLimit]);
  }

  // ── settings ───────────────────────────────────────────────────

  Future<int> getHistoryLimit() async {
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['history_limit'],
    );
    if (result.isEmpty) return 500;
    return int.tryParse(result.first['value'] as String) ?? 500;
  }

  Future<void> setHistoryLimit(int limit) async {
    await db.insert(
      'settings',
      {'key': 'history_limit', 'value': limit.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _cachedHistoryLimit = limit;
  }

  // ── generic settings ─────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── TTL auto-clear ──────────────────────────────────────────────

  Future<void> clearExpiredItems() async {
    final ttlEnabled = await getSetting('ttl_enabled');
    if (ttlEnabled != 'true') return;

    final ttlHoursStr = await getSetting('ttl_hours');
    final ttlHours = int.tryParse(ttlHoursStr ?? '') ?? 72;

    final cutoff = DateTime.now()
        .subtract(Duration(hours: ttlHours))
        .millisecondsSinceEpoch;

    await db.rawDelete(
      'DELETE FROM clipboard_items WHERE pinned = 0 AND created_at < ?',
      [cutoff],
    );
  }

  // ── exclusions ─────────────────────────────────────────────────

  Future<bool> isAppExcluded(String appName) async {
    final result = await db.query(
      'app_exclusions',
      where: 'app_name = ? AND blocked = 1',
      whereArgs: [appName],
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> fetchExclusions() async {
    return await db.query('app_exclusions', orderBy: 'app_name');
  }

  Future<void> setExclusion(String appName, bool blocked) async {
    if (blocked) {
      await db.insert(
        'app_exclusions',
        {'app_name': appName, 'blocked': 1},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await db.delete(
        'app_exclusions',
        where: 'app_name = ?',
        whereArgs: [appName],
      );
    }
  }

  Future<void> close() async {
    await _db?.close();
  }
}
