pub mod schema;
pub mod connection;
pub mod operations;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_database_initialization() {
        let db = connection::Database::new_in_memory().unwrap();

        // Verify tables exist
        let table_count: i32 = db.conn
            .query_row(
                "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name IN ('clipboard_history', 'clipboard_history_fts')",
                [],
                |row| row.get(0)
            )
            .unwrap();

        assert_eq!(table_count, 2);
    }

    #[test]
    fn test_insert_clipboard_entry() {
        let db = connection::Database::new_in_memory().unwrap();
        let entry = operations::ClipboardEntry {
            id: None,
            content: "Hello, World!".to_string(),
            content_type: "text".to_string(),
            timestamp: chrono::Utc::now().timestamp(),
            preview: "Hello, World!".to_string(),
        };

        let id = operations::insert_entry(&db.conn, &entry).unwrap();
        assert!(id > 0);
    }

    #[test]
    fn test_get_recent_entries() {
        let db = connection::Database::new_in_memory().unwrap();

        // Insert 3 entries
        for i in 1..=3 {
            let entry = operations::ClipboardEntry {
                id: None,
                content: format!("Content {}", i),
                content_type: "text".to_string(),
                timestamp: chrono::Utc::now().timestamp() + i,
                preview: format!("Content {}", i),
            };
            operations::insert_entry(&db.conn, &entry).unwrap();
        }

        let entries = operations::get_recent_entries(&db.conn, 10).unwrap();
        assert_eq!(entries.len(), 3);
        assert_eq!(entries[0].content, "Content 3"); // Most recent first
    }

    #[test]
    fn test_search_entries() {
        let db = connection::Database::new_in_memory().unwrap();

        let entry = operations::ClipboardEntry {
            id: None,
            content: "The quick brown fox".to_string(),
            content_type: "text".to_string(),
            timestamp: chrono::Utc::now().timestamp(),
            preview: "The quick brown fox".to_string(),
        };
        operations::insert_entry(&db.conn, &entry).unwrap();

        let results = operations::search_entries(&db.conn, "quick").unwrap();
        assert_eq!(results.len(), 1);
        assert!(results[0].content.contains("quick"));
    }

    #[test]
    fn test_delete_all_entries() {
        let db = connection::Database::new_in_memory().unwrap();

        let entry = operations::ClipboardEntry {
            id: None,
            content: "Test".to_string(),
            content_type: "text".to_string(),
            timestamp: chrono::Utc::now().timestamp(),
            preview: "Test".to_string(),
        };
        operations::insert_entry(&db.conn, &entry).unwrap();

        operations::delete_all_entries(&db.conn).unwrap();

        let entries = operations::get_recent_entries(&db.conn, 10).unwrap();
        assert_eq!(entries.len(), 0);
    }
}
