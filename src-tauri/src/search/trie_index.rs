use radix_trie::Trie;
use lru::LruCache;
use std::num::NonZeroUsize;

pub struct TrieIndex {
    trie: Trie<String, Vec<i64>>,
    lru: LruCache<i64, String>,
    capacity: usize,
}

impl TrieIndex {
    pub fn new(capacity: usize) -> Self {
        TrieIndex {
            trie: Trie::new(),
            lru: LruCache::new(NonZeroUsize::new(capacity).unwrap()),
            capacity,
        }
    }

    pub fn insert(&mut self, id: i64, content: &str) {
        // Normalize content to lowercase for case-insensitive search
        let normalized = content.to_lowercase();

        // Split into words and add each word to trie
        for word in normalized.split_whitespace() {
            let word_string = word.to_string();

            // Get or create entry in trie
            if let Some(ids) = self.trie.get_mut(&word_string) {
                if !ids.contains(&id) {
                    ids.push(id);
                }
            } else {
                self.trie.insert(word_string, vec![id]);
            }
        }

        // Add to LRU cache
        if let Some((evicted_id, evicted_content)) = self.lru.push(id, normalized.clone()) {
            // Remove evicted entry from trie
            self.remove_from_trie(evicted_id, &evicted_content);
        }
    }

    pub fn search_prefix(&self, prefix: &str) -> Vec<i64> {
        let normalized_prefix = prefix.to_lowercase();
        let mut result_ids = Vec::new();

        // Find all keys that start with prefix
        for (_, ids) in self.trie.iter() {
            result_ids.extend(ids);
        }

        // Use get_ancestor to find entries with matching prefix
        if let Some(subtrie) = self.trie.get_ancestor(&normalized_prefix) {
            for (_, ids) in subtrie.iter() {
                result_ids.extend(ids);
            }
        }

        // Deduplicate
        result_ids.sort();
        result_ids.dedup();
        result_ids
    }

    fn remove_from_trie(&mut self, id: i64, content: &str) {
        for word in content.split_whitespace() {
            let word_string = word.to_string();
            if let Some(ids) = self.trie.get_mut(&word_string) {
                ids.retain(|&x| x != id);
                if ids.is_empty() {
                    self.trie.remove(&word_string);
                }
            }
        }
    }

    pub fn clear(&mut self) {
        self.trie = Trie::new();
        self.lru.clear();
    }
}
