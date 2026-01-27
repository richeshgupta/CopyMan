pub mod trie_index;
pub mod hybrid;

#[cfg(test)]
mod tests {
    use super::trie_index::TrieIndex;
    use super::hybrid::HybridSearch;
    use crate::db::connection::Database;
    use crate::db::operations::{ClipboardEntry, insert_entry};

    #[test]
    fn test_trie_insert_and_search() {
        let mut trie = TrieIndex::new(100);

        trie.insert(1, "hello world");
        trie.insert(2, "hello rust");
        trie.insert(3, "goodbye world");

        let results = trie.search_prefix("hello");
        assert_eq!(results.len(), 2);
        assert!(results.contains(&1));
        assert!(results.contains(&2));
    }

    #[test]
    fn test_trie_case_insensitive() {
        let mut trie = TrieIndex::new(100);

        trie.insert(1, "Hello World");

        let results = trie.search_prefix("hello");
        assert_eq!(results.len(), 1);
        assert!(results.contains(&1));
    }

    #[test]
    fn test_trie_lru_eviction() {
        let mut trie = TrieIndex::new(2); // Capacity of 2

        trie.insert(1, "first");
        trie.insert(2, "second");
        trie.insert(3, "third"); // Should evict "first"

        let results = trie.search_prefix("first");
        assert_eq!(results.len(), 0); // "first" should be evicted

        let results = trie.search_prefix("second");
        assert_eq!(results.len(), 1);
    }

    #[test]
    fn test_hybrid_search_trie_first() {
        let db = Database::new_in_memory().unwrap();
        let mut search = HybridSearch::new(&db.conn, 100).unwrap();

        // Insert entries
        for i in 1..=3 {
            let entry = ClipboardEntry {
                id: None,
                content: format!("hello world {}", i),
                content_type: "text".to_string(),
                timestamp: chrono::Utc::now().timestamp() + i,
                preview: format!("hello world {}", i),
                is_pinned: false,
                pin_order: None,
            };
            let id = insert_entry(&db.conn, &entry).unwrap();
            search.add_to_trie(id, &entry.content);
        }

        // Search should use Trie first
        let results = search.search(&db.conn, "hello").unwrap();
        assert!(results.len() >= 3);
    }

    #[test]
    fn test_hybrid_search_fts5_fallback() {
        let db = Database::new_in_memory().unwrap();
        let search = HybridSearch::new(&db.conn, 100).unwrap();

        // Insert entry to DB but not Trie
        let entry = ClipboardEntry {
            id: None,
            content: "unique search term".to_string(),
            content_type: "text".to_string(),
            timestamp: chrono::Utc::now().timestamp(),
            preview: "unique search term".to_string(),
            is_pinned: false,
            pin_order: None,
        };
        insert_entry(&db.conn, &entry).unwrap();

        // Search should fallback to FTS5
        let results = search.search(&db.conn, "unique").unwrap();
        assert_eq!(results.len(), 1);
    }
}
