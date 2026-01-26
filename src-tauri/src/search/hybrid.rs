use super::trie_index::TrieIndex;
use crate::db::operations::{ClipboardEntry, search_entries, get_entry_by_id};
use rusqlite::{Connection, Result};
use std::collections::HashSet;

pub struct HybridSearch {
    trie: TrieIndex,
}

impl HybridSearch {
    pub fn new(_conn: &Connection, capacity: usize) -> Result<Self> {
        Ok(HybridSearch {
            trie: TrieIndex::new(capacity),
        })
    }

    pub fn add_to_trie(&mut self, id: i64, content: &str) {
        self.trie.insert(id, content);
    }

    pub fn search(&self, conn: &Connection, query: &str) -> Result<Vec<ClipboardEntry>> {
        let mut seen_ids = HashSet::new();
        let mut results = Vec::new();

        // Step 1: Search in Trie (fast, recent items)
        let trie_ids = self.trie.search_prefix(query);
        for id in trie_ids {
            if let Some(entry) = get_entry_by_id(conn, id)? {
                results.push(entry);
                seen_ids.insert(id);
            }
        }

        // Step 2: Search in FTS5 (comprehensive, all history)
        let fts_results = search_entries(conn, query)?;
        for entry in fts_results {
            if let Some(id) = entry.id {
                if !seen_ids.contains(&id) {
                    results.push(entry);
                    seen_ids.insert(id);
                }
            }
        }

        // Sort by timestamp (most recent first)
        results.sort_by(|a, b| b.timestamp.cmp(&a.timestamp));

        Ok(results)
    }

    pub fn clear(&mut self) {
        self.trie.clear();
    }
}
