#[test]
fn test_dependencies_available() {
    // This will fail until we add dependencies
    use rusqlite::Connection;
    use radix_trie::Trie;
    use lru::LruCache;

    let _conn = Connection::open_in_memory().unwrap();
    let _trie: Trie<String, u32> = Trie::new();
    let _cache: LruCache<String, String> = LruCache::new(std::num::NonZeroUsize::new(10).unwrap());
}
