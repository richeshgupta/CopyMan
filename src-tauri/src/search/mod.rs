pub mod trie_index;

#[cfg(test)]
mod tests {
    use super::trie_index::TrieIndex;

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
}
