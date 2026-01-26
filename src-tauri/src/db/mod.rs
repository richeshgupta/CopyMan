pub mod schema;
pub mod connection;

#[cfg(test)]
mod tests {
    use super::connection::Database;

    #[test]
    fn test_database_initialization() {
        let db = Database::new_in_memory().unwrap();

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
}
