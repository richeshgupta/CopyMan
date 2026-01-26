use rusqlite::{Connection, Result, params, OptionalExtension};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClipboardEntry {
    pub id: Option<i64>,
    pub content: String,
    pub content_type: String,
    pub timestamp: i64,
    pub preview: String,
}

pub fn insert_entry(conn: &Connection, entry: &ClipboardEntry) -> Result<i64> {
    conn.execute(
        "INSERT INTO clipboard_history (content, content_type, timestamp, preview) VALUES (?1, ?2, ?3, ?4)",
        params![entry.content, entry.content_type, entry.timestamp, entry.preview],
    )?;
    Ok(conn.last_insert_rowid())
}

pub fn get_recent_entries(conn: &Connection, limit: usize) -> Result<Vec<ClipboardEntry>> {
    let mut stmt = conn.prepare(
        "SELECT id, content, content_type, timestamp, preview FROM clipboard_history ORDER BY timestamp DESC LIMIT ?1"
    )?;

    let entries = stmt.query_map([limit], |row| {
        Ok(ClipboardEntry {
            id: Some(row.get(0)?),
            content: row.get(1)?,
            content_type: row.get(2)?,
            timestamp: row.get(3)?,
            preview: row.get(4)?,
        })
    })?
    .collect::<Result<Vec<_>>>()?;

    Ok(entries)
}

pub fn search_entries(conn: &Connection, query: &str) -> Result<Vec<ClipboardEntry>> {
    let mut stmt = conn.prepare(
        "SELECT id, content, content_type, timestamp, preview
         FROM clipboard_history
         WHERE id IN (SELECT rowid FROM clipboard_history_fts WHERE clipboard_history_fts MATCH ?1)
         ORDER BY timestamp DESC"
    )?;

    let entries = stmt.query_map([query], |row| {
        Ok(ClipboardEntry {
            id: Some(row.get(0)?),
            content: row.get(1)?,
            content_type: row.get(2)?,
            timestamp: row.get(3)?,
            preview: row.get(4)?,
        })
    })?
    .collect::<Result<Vec<_>>>()?;

    Ok(entries)
}

pub fn delete_all_entries(conn: &Connection) -> Result<()> {
    conn.execute("DELETE FROM clipboard_history", [])?;
    Ok(())
}

pub fn get_entry_by_id(conn: &Connection, id: i64) -> Result<Option<ClipboardEntry>> {
    let mut stmt = conn.prepare(
        "SELECT id, content, content_type, timestamp, preview FROM clipboard_history WHERE id = ?1"
    )?;

    let entry = stmt.query_row([id], |row| {
        Ok(ClipboardEntry {
            id: Some(row.get(0)?),
            content: row.get(1)?,
            content_type: row.get(2)?,
            timestamp: row.get(3)?,
            preview: row.get(4)?,
        })
    }).optional()?;

    Ok(entry)
}
