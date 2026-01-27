use rusqlite::{Connection, Result};

pub const INIT_SQL: &str = r#"
CREATE TABLE IF NOT EXISTS clipboard_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content TEXT NOT NULL,
    content_type TEXT NOT NULL DEFAULT 'text',
    timestamp INTEGER NOT NULL,
    preview TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_timestamp ON clipboard_history(timestamp DESC);

CREATE VIRTUAL TABLE IF NOT EXISTS clipboard_history_fts USING fts5(
    content,
    preview,
    content='clipboard_history',
    content_rowid='id'
);

CREATE TRIGGER IF NOT EXISTS clipboard_history_ai AFTER INSERT ON clipboard_history BEGIN
    INSERT INTO clipboard_history_fts(rowid, content, preview)
    VALUES (new.id, new.content, new.preview);
END;

CREATE TRIGGER IF NOT EXISTS clipboard_history_ad AFTER DELETE ON clipboard_history BEGIN
    DELETE FROM clipboard_history_fts WHERE rowid = old.id;
END;

CREATE TRIGGER IF NOT EXISTS clipboard_history_au AFTER UPDATE ON clipboard_history BEGIN
    UPDATE clipboard_history_fts SET content = new.content, preview = new.preview
    WHERE rowid = new.id;
END;
"#;

pub fn get_schema_version(conn: &Connection) -> Result<i32> {
    let version: i32 = conn.query_row(
        "PRAGMA user_version",
        [],
        |row| row.get(0)
    )?;
    Ok(version)
}

pub fn set_schema_version(conn: &Connection, version: i32) -> Result<()> {
    conn.execute(&format!("PRAGMA user_version = {}", version), [])?;
    Ok(())
}

pub fn migrate_to_v2(conn: &Connection) -> Result<()> {
    println!("Migrating database to version 2 (adding pinning support)...");

    // Check if columns already exist (in case of partial migration)
    let has_is_pinned: Result<i32, _> = conn.query_row(
        "SELECT COUNT(*) FROM pragma_table_info('clipboard_history') WHERE name='is_pinned'",
        [],
        |row| row.get(0)
    );

    if has_is_pinned.unwrap_or(0) == 0 {
        conn.execute(
            "ALTER TABLE clipboard_history ADD COLUMN is_pinned INTEGER DEFAULT 0",
            [],
        )?;
    }

    let has_pin_order: Result<i32, _> = conn.query_row(
        "SELECT COUNT(*) FROM pragma_table_info('clipboard_history') WHERE name='pin_order'",
        [],
        |row| row.get(0)
    );

    if has_pin_order.unwrap_or(0) == 0 {
        conn.execute(
            "ALTER TABLE clipboard_history ADD COLUMN pin_order INTEGER",
            [],
        )?;
    }

    // Create index for faster queries
    conn.execute(
        "CREATE INDEX IF NOT EXISTS idx_pinned ON clipboard_history(is_pinned, pin_order)",
        [],
    )?;

    set_schema_version(conn, 2)?;
    println!("Migration to version 2 complete");
    Ok(())
}

pub fn run_migrations(conn: &Connection) -> Result<()> {
    let current_version = get_schema_version(conn)?;

    match current_version {
        0 | 1 => {
            migrate_to_v2(conn)?;
        }
        2 => {
            // Already up to date
        }
        _ => {
            println!("Unknown schema version: {}", current_version);
        }
    }

    Ok(())
}
