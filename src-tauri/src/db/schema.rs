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
