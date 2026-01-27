use rusqlite::{Connection, Result, params, OptionalExtension};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClipboardEntry {
    pub id: Option<i64>,
    pub content: String,
    pub content_type: String,
    pub timestamp: i64,
    pub preview: String,
    pub is_pinned: bool,
    pub pin_order: Option<i32>,
}

pub fn insert_entry(conn: &Connection, entry: &ClipboardEntry) -> Result<i64> {
    conn.execute(
        "INSERT INTO clipboard_history (content, content_type, timestamp, preview, is_pinned, pin_order) VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
        params![entry.content, entry.content_type, entry.timestamp, entry.preview, if entry.is_pinned { 1 } else { 0 }, entry.pin_order],
    )?;
    Ok(conn.last_insert_rowid())
}

pub fn get_recent_entries(conn: &Connection, limit: usize) -> Result<Vec<ClipboardEntry>> {
    let mut stmt = conn.prepare(
        "SELECT id, content, content_type, timestamp, preview, is_pinned, pin_order
         FROM clipboard_history
         ORDER BY is_pinned DESC, pin_order ASC, timestamp DESC
         LIMIT ?1"
    )?;

    let entries = stmt.query_map([limit], |row| {
        Ok(ClipboardEntry {
            id: Some(row.get(0)?),
            content: row.get(1)?,
            content_type: row.get(2)?,
            timestamp: row.get(3)?,
            preview: row.get(4)?,
            is_pinned: row.get::<_, i32>(5)? == 1,
            pin_order: row.get(6)?,
        })
    })?
    .collect::<Result<Vec<_>>>()?;

    Ok(entries)
}

pub fn search_entries(conn: &Connection, query: &str) -> Result<Vec<ClipboardEntry>> {
    let mut stmt = conn.prepare(
        "SELECT id, content, content_type, timestamp, preview, is_pinned, pin_order
         FROM clipboard_history
         WHERE id IN (SELECT rowid FROM clipboard_history_fts WHERE clipboard_history_fts MATCH ?1)
         ORDER BY is_pinned DESC, pin_order ASC, timestamp DESC"
    )?;

    let entries = stmt.query_map([query], |row| {
        Ok(ClipboardEntry {
            id: Some(row.get(0)?),
            content: row.get(1)?,
            content_type: row.get(2)?,
            timestamp: row.get(3)?,
            preview: row.get(4)?,
            is_pinned: row.get::<_, i32>(5)? == 1,
            pin_order: row.get(6)?,
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
        "SELECT id, content, content_type, timestamp, preview, is_pinned, pin_order FROM clipboard_history WHERE id = ?1"
    )?;

    let entry = stmt.query_row([id], |row| {
        Ok(ClipboardEntry {
            id: Some(row.get(0)?),
            content: row.get(1)?,
            content_type: row.get(2)?,
            timestamp: row.get(3)?,
            preview: row.get(4)?,
            is_pinned: row.get::<_, i32>(5)? == 1,
            pin_order: row.get(6)?,
        })
    }).optional()?;

    Ok(entry)
}

pub fn pin_entry(conn: &Connection, id: i64) -> Result<()> {
    // Get max pin_order
    let max_order: Option<i32> = conn.query_row(
        "SELECT MAX(pin_order) FROM clipboard_history WHERE is_pinned = 1",
        [],
        |row| row.get(0)
    ).unwrap_or(None);

    let new_order = max_order.map(|o| o + 1).unwrap_or(1);

    conn.execute(
        "UPDATE clipboard_history SET is_pinned = 1, pin_order = ?1 WHERE id = ?2",
        params![new_order, id],
    )?;

    Ok(())
}

pub fn unpin_entry(conn: &Connection, id: i64) -> Result<()> {
    conn.execute(
        "UPDATE clipboard_history SET is_pinned = 0, pin_order = NULL WHERE id = ?1",
        params![id],
    )?;
    Ok(())
}

pub fn delete_entry(conn: &Connection, id: i64) -> Result<()> {
    conn.execute(
        "DELETE FROM clipboard_history WHERE id = ?1",
        params![id],
    )?;
    Ok(())
}

pub fn get_pinned_entries(conn: &Connection) -> Result<Vec<ClipboardEntry>> {
    let mut stmt = conn.prepare(
        "SELECT id, content, content_type, timestamp, preview, is_pinned, pin_order
         FROM clipboard_history
         WHERE is_pinned = 1
         ORDER BY pin_order ASC"
    )?;

    let entries = stmt.query_map([], |row| {
        Ok(ClipboardEntry {
            id: Some(row.get(0)?),
            content: row.get(1)?,
            content_type: row.get(2)?,
            timestamp: row.get(3)?,
            preview: row.get(4)?,
            is_pinned: row.get::<_, i32>(5)? == 1,
            pin_order: row.get(6)?,
        })
    })?
    .collect::<Result<Vec<_>>>()?;

    Ok(entries)
}
