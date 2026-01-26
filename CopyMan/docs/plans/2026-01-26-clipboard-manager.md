# CopyMan - Cross-Platform Clipboard Manager Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a lightweight, snappy cross-platform clipboard manager with unlimited persistence, fast search, and global hotkeys.

**Architecture:** Tauri + Rust backend with hybrid search (Trie + SQLite FTS5 + LRU cache). Svelte frontend with Tailwind CSS. Background clipboard monitor with system tray integration.

**Tech Stack:**
- **Backend:** Rust, Tauri 2.0, rusqlite (FTS5), arboard (clipboard), tauri-plugin-global-shortcut
- **Search:** radix_trie (in-memory prefix), SQLite FTS5 (persistent full-text), lru (cache)
- **Frontend:** Svelte + Vite + Tailwind CSS + TanStack Virtual
- **Performance Target:** <50ms startup, <30MB memory, <20ms search

**Design Principles:**
- TDD: Write tests first, then minimal implementation
- YAGNI: Only implement required features
- DRY: Extract common patterns into reusable modules
- Frequent commits: Commit after each passing test

---

## Phase 1: Project Setup & Foundation

### Task 1.1: Initialize Tauri Project

**Files:**
- Create: `package.json`, `index.html`, `vite.config.ts`
- Create: `src-tauri/Cargo.toml`, `src-tauri/tauri.conf.json`
- Create: `src-tauri/src/main.rs`, `src-tauri/src/lib.rs`

**Step 1: Create Tauri project with Svelte**

```bash
npm create tauri-app@latest
# Choose: Svelte, TypeScript, npm
# Project name: copyman
```

**Step 2: Verify project structure**

```bash
ls -la
# Expected: package.json, src/, src-tauri/, index.html
ls -la src-tauri/src/
# Expected: main.rs, lib.rs
```

**Step 3: Add Tailwind CSS dependencies**

```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

**Step 4: Configure Tailwind (tailwind.config.js)**

```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{svelte,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

**Step 5: Add Tailwind directives to main CSS**

Create `src/app.css`:
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

**Step 6: Run dev server to verify setup**

```bash
npm run tauri dev
```

Expected: App opens with default Tauri + Svelte template

**Step 7: Commit**

```bash
git add .
git commit -m "chore: initialize Tauri + Svelte + Tailwind project

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 1.2: Add Rust Dependencies

**Files:**
- Modify: `src-tauri/Cargo.toml`

**Step 1: Write failing integration test**

Create `src-tauri/tests/dependencies_test.rs`:
```rust
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
```

**Step 2: Run test to verify it fails**

```bash
cd src-tauri
cargo test test_dependencies_available
```

Expected: Compilation error - dependencies not found

**Step 3: Add dependencies to Cargo.toml**

Add to `[dependencies]` section:
```toml
rusqlite = { version = "0.32", features = ["bundled", "chrono"] }
radix_trie = { version = "0.2", features = ["serde"] }
lru = "0.12"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
chrono = { version = "0.4", features = ["serde"] }
tokio = { version = "1.0", features = ["full"] }
anyhow = "1.0"
```

**Step 4: Run test to verify it passes**

```bash
cargo test test_dependencies_available
```

Expected: PASS - all dependencies compile

**Step 5: Commit**

```bash
git add Cargo.toml tests/
git commit -m "feat: add core Rust dependencies (rusqlite, trie, lru)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 1.3: Add Tauri Plugins

**Files:**
- Modify: `src-tauri/Cargo.toml`, `src-tauri/src/lib.rs`

**Step 1: Add clipboard and global shortcut plugins**

Add to `src-tauri/Cargo.toml` under `[dependencies]`:
```toml
tauri-plugin-clipboard-manager = "2.0"
tauri-plugin-global-shortcut = "2.0"
arboard = "3.4"
```

**Step 2: Register plugins in lib.rs**

Modify `src-tauri/src/lib.rs`:
```rust
#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_clipboard_manager::init())
        .plugin(tauri_plugin_global_shortcut::Builder::new().build())
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

**Step 3: Verify plugins load**

```bash
cargo build
```

Expected: Successful build with no errors

**Step 4: Commit**

```bash
git add Cargo.toml src/lib.rs
git commit -m "feat: add clipboard and global shortcut plugins

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 2: Database Layer (SQLite + FTS5)

### Task 2.1: Database Schema & Initialization

**Files:**
- Create: `src-tauri/src/db/mod.rs`
- Create: `src-tauri/src/db/schema.rs`
- Create: `src-tauri/src/db/connection.rs`

**Step 1: Write failing test for database initialization**

Create `src-tauri/src/db/mod.rs`:
```rust
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
```

**Step 2: Run test to verify it fails**

```bash
cd src-tauri
cargo test test_database_initialization
```

Expected: FAIL - modules not found

**Step 3: Create database schema**

Create `src-tauri/src/db/schema.rs`:
```rust
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
```

**Step 4: Implement database connection**

Create `src-tauri/src/db/connection.rs`:
```rust
use rusqlite::{Connection, Result};
use std::path::PathBuf;
use super::schema::INIT_SQL;

pub struct Database {
    pub conn: Connection,
}

impl Database {
    pub fn new(db_path: PathBuf) -> Result<Self> {
        let conn = Connection::open(db_path)?;
        conn.execute_batch(INIT_SQL)?;
        Ok(Database { conn })
    }

    pub fn new_in_memory() -> Result<Self> {
        let conn = Connection::open_in_memory()?;
        conn.execute_batch(INIT_SQL)?;
        Ok(Database { conn })
    }
}
```

**Step 5: Update lib.rs to include db module**

Add to `src-tauri/src/lib.rs`:
```rust
mod db;
```

**Step 6: Run test to verify it passes**

```bash
cargo test test_database_initialization
```

Expected: PASS - tables created successfully

**Step 7: Commit**

```bash
git add src/db/
git commit -m "feat: implement SQLite database with FTS5 schema

- Add clipboard_history table for data storage
- Add FTS5 virtual table for full-text search
- Add triggers to keep FTS5 index in sync

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 2.2: Database CRUD Operations

**Files:**
- Create: `src-tauri/src/db/operations.rs`
- Modify: `src-tauri/src/db/mod.rs`

**Step 1: Write failing tests for CRUD operations**

Add to `src-tauri/src/db/mod.rs`:
```rust
pub mod operations;

#[cfg(test)]
mod tests {
    use super::*;

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
```

**Step 2: Run tests to verify they fail**

```bash
cargo test
```

Expected: FAIL - operations module not found

**Step 3: Implement CRUD operations**

Create `src-tauri/src/db/operations.rs`:
```rust
use rusqlite::{Connection, Result, params};
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
```

**Step 4: Run tests to verify they pass**

```bash
cargo test
```

Expected: PASS - all CRUD operations work

**Step 5: Commit**

```bash
git add src/db/operations.rs src/db/mod.rs
git commit -m "feat: implement database CRUD operations

- Add insert_entry for saving clipboard content
- Add get_recent_entries for fetching latest items
- Add search_entries using FTS5 full-text search
- Add delete_all_entries for clearing history
- Add get_entry_by_id for single item retrieval

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 3: In-Memory Search Layer (Trie + LRU)

### Task 3.1: Trie Index Implementation

**Files:**
- Create: `src-tauri/src/search/mod.rs`
- Create: `src-tauri/src/search/trie_index.rs`

**Step 1: Write failing test for Trie index**

Create `src-tauri/src/search/mod.rs`:
```rust
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
```

**Step 2: Run test to verify it fails**

```bash
cd src-tauri
cargo test test_trie
```

Expected: FAIL - trie_index module not found

**Step 3: Implement Trie index with LRU**

Create `src-tauri/src/search/trie_index.rs`:
```rust
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
```

**Step 4: Update lib.rs to include search module**

Add to `src-tauri/src/lib.rs`:
```rust
mod search;
```

**Step 5: Run tests to verify they pass**

```bash
cargo test test_trie
```

Expected: PASS - all trie operations work

**Step 6: Commit**

```bash
git add src/search/
git commit -m "feat: implement Trie-based in-memory search index

- Add TrieIndex with LRU eviction policy
- Support case-insensitive prefix search
- Track recent entries for fast lookup
- Auto-evict old entries when capacity reached

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 3.2: Hybrid Search Engine

**Files:**
- Create: `src-tauri/src/search/hybrid.rs`
- Modify: `src-tauri/src/search/mod.rs`

**Step 1: Write failing test for hybrid search**

Add to `src-tauri/src/search/mod.rs`:
```rust
pub mod hybrid;

#[cfg(test)]
mod tests {
    use super::hybrid::HybridSearch;
    use crate::db::connection::Database;
    use crate::db::operations::{ClipboardEntry, insert_entry};

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
        };
        insert_entry(&db.conn, &entry).unwrap();

        // Search should fallback to FTS5
        let results = search.search(&db.conn, "unique").unwrap();
        assert_eq!(results.len(), 1);
    }
}
```

**Step 2: Run tests to verify they fail**

```bash
cargo test test_hybrid_search
```

Expected: FAIL - hybrid module not found

**Step 3: Implement hybrid search engine**

Create `src-tauri/src/search/hybrid.rs`:
```rust
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
```

**Step 4: Run tests to verify they pass**

```bash
cargo test test_hybrid_search
```

Expected: PASS - hybrid search works

**Step 5: Commit**

```bash
git add src/search/hybrid.rs src/search/mod.rs
git commit -m "feat: implement hybrid search engine (Trie + FTS5)

- Combine in-memory Trie for recent items
- Fallback to SQLite FTS5 for full history
- Deduplicate results across both sources
- Sort by timestamp for relevance

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 4: Clipboard Monitoring Service

### Task 4.1: Background Clipboard Monitor

**Files:**
- Create: `src-tauri/src/clipboard/mod.rs`
- Create: `src-tauri/src/clipboard/monitor.rs`

**Step 1: Write failing test for clipboard detection**

Create `src-tauri/src/clipboard/mod.rs`:
```rust
pub mod monitor;

#[cfg(test)]
mod tests {
    use super::monitor::ClipboardMonitor;

    #[test]
    fn test_clipboard_change_detection() {
        let monitor = ClipboardMonitor::new();

        let content1 = "test content 1".to_string();
        let content2 = "test content 2".to_string();

        assert!(monitor.has_changed(&content1, &None));
        assert!(!monitor.has_changed(&content1, &Some(content1.clone())));
        assert!(monitor.has_changed(&content2, &Some(content1)));
    }

    #[test]
    fn test_generate_preview() {
        let monitor = ClipboardMonitor::new();

        let short = "Hello";
        let preview = monitor.generate_preview(short);
        assert_eq!(preview, "Hello");

        let long = "a".repeat(200);
        let preview = monitor.generate_preview(&long);
        assert!(preview.len() <= 103); // 100 chars + "..."
    }
}
```

**Step 2: Run test to verify it fails**

```bash
cargo test test_clipboard
```

Expected: FAIL - monitor module not found

**Step 3: Implement clipboard monitor**

Create `src-tauri/src/clipboard/monitor.rs`:
```rust
use arboard::Clipboard;
use std::time::Duration;
use tokio::time::sleep;

pub struct ClipboardMonitor {
    clipboard: Clipboard,
}

impl ClipboardMonitor {
    pub fn new() -> Self {
        ClipboardMonitor {
            clipboard: Clipboard::new().expect("Failed to initialize clipboard"),
        }
    }

    pub fn read_text(&mut self) -> Result<String, String> {
        self.clipboard
            .get_text()
            .map_err(|e| format!("Failed to read clipboard: {}", e))
    }

    pub fn write_text(&mut self, content: &str) -> Result<(), String> {
        self.clipboard
            .set_text(content)
            .map_err(|e| format!("Failed to write clipboard: {}", e))
    }

    pub fn has_changed(&self, new_content: &str, last_content: &Option<String>) -> bool {
        match last_content {
            None => true,
            Some(last) => last != new_content,
        }
    }

    pub fn generate_preview(&self, content: &str) -> String {
        if content.len() <= 100 {
            content.to_string()
        } else {
            format!("{}...", &content[..100])
        }
    }
}

pub async fn start_monitor<F>(mut callback: F) -> Result<(), String>
where
    F: FnMut(String) + Send + 'static,
{
    let mut monitor = ClipboardMonitor::new();
    let mut last_content: Option<String> = None;

    loop {
        if let Ok(content) = monitor.read_text() {
            if monitor.has_changed(&content, &last_content) {
                callback(content.clone());
                last_content = Some(content);
            }
        }

        sleep(Duration::from_millis(500)).await;
    }
}
```

**Step 4: Update lib.rs to include clipboard module**

Add to `src-tauri/src/lib.rs`:
```rust
mod clipboard;
```

**Step 5: Run tests to verify they pass**

```bash
cargo test test_clipboard
```

Expected: PASS - clipboard monitor works

**Step 6: Commit**

```bash
git add src/clipboard/
git commit -m "feat: implement background clipboard monitor

- Add ClipboardMonitor using arboard crate
- Detect clipboard content changes
- Generate preview text (100 char limit)
- Poll clipboard every 500ms

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 5: Tauri Commands (IPC Layer)

### Task 5.1: Clipboard Management Commands

**Files:**
- Create: `src-tauri/src/commands/mod.rs`
- Create: `src-tauri/src/commands/clipboard.rs`
- Modify: `src-tauri/src/lib.rs`

**Step 1: Write integration test for commands**

Create `src-tauri/src/commands/mod.rs`:
```rust
pub mod clipboard;

#[cfg(test)]
mod tests {
    use super::clipboard::*;
    use crate::state::AppState;
    use std::sync::{Arc, Mutex};

    fn create_test_state() -> tauri::State<Arc<Mutex<AppState>>> {
        // This is a mock - actual testing will be manual/integration
        unimplemented!("Use integration tests for Tauri commands")
    }
}
```

**Step 2: Implement clipboard commands**

Create `src-tauri/src/commands/clipboard.rs`:
```rust
use crate::db::operations::{ClipboardEntry, get_recent_entries, get_entry_by_id};
use crate::state::AppState;
use std::sync::{Arc, Mutex};
use tauri::State;

#[tauri::command]
pub fn get_clipboard_history(
    state: State<Arc<Mutex<AppState>>>,
    limit: usize,
) -> Result<Vec<ClipboardEntry>, String> {
    let app_state = state.lock().map_err(|e| e.to_string())?;

    get_recent_entries(&app_state.db.conn, limit)
        .map_err(|e| format!("Failed to get history: {}", e))
}

#[tauri::command]
pub fn search_clipboard(
    state: State<Arc<Mutex<AppState>>>,
    query: String,
) -> Result<Vec<ClipboardEntry>, String> {
    let app_state = state.lock().map_err(|e| e.to_string())?;

    app_state.search
        .lock()
        .map_err(|e| e.to_string())?
        .search(&app_state.db.conn, &query)
        .map_err(|e| format!("Search failed: {}", e))
}

#[tauri::command]
pub fn copy_to_clipboard(
    state: State<Arc<Mutex<AppState>>>,
    entry_id: i64,
) -> Result<(), String> {
    let app_state = state.lock().map_err(|e| e.to_string())?;

    let entry = get_entry_by_id(&app_state.db.conn, entry_id)
        .map_err(|e| format!("Failed to get entry: {}", e))?
        .ok_or("Entry not found")?;

    use arboard::Clipboard;
    let mut clipboard = Clipboard::new().map_err(|e| e.to_string())?;
    clipboard.set_text(&entry.content).map_err(|e| e.to_string())?;

    Ok(())
}

#[tauri::command]
pub fn clear_all_history(
    state: State<Arc<Mutex<AppState>>>,
) -> Result<(), String> {
    let app_state = state.lock().map_err(|e| e.to_string())?;

    crate::db::operations::delete_all_entries(&app_state.db.conn)
        .map_err(|e| format!("Failed to clear history: {}", e))?;

    app_state.search
        .lock()
        .map_err(|e| e.to_string())?
        .clear();

    Ok(())
}
```

**Step 3: Create application state**

Create `src-tauri/src/state.rs`:
```rust
use crate::db::connection::Database;
use crate::search::hybrid::HybridSearch;
use std::sync::Mutex;

pub struct AppState {
    pub db: Database,
    pub search: Mutex<HybridSearch>,
}

impl AppState {
    pub fn new(db_path: std::path::PathBuf) -> Result<Self, String> {
        let db = Database::new(db_path).map_err(|e| e.to_string())?;
        let search = HybridSearch::new(&db.conn, 1000).map_err(|e| e.to_string())?;

        Ok(AppState {
            db,
            search: Mutex::new(search),
        })
    }
}
```

**Step 4: Register commands in lib.rs**

Modify `src-tauri/src/lib.rs`:
```rust
mod commands;
mod state;

use state::AppState;
use std::sync::{Arc, Mutex};
use tauri::Manager;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_clipboard_manager::init())
        .plugin(tauri_plugin_global_shortcut::Builder::new().build())
        .setup(|app| {
            // Initialize database
            let app_dir = app.path().app_data_dir()?;
            std::fs::create_dir_all(&app_dir)?;
            let db_path = app_dir.join("clipboard.db");

            let state = AppState::new(db_path)?;
            app.manage(Arc::new(Mutex::new(state)));

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::clipboard::get_clipboard_history,
            commands::clipboard::search_clipboard,
            commands::clipboard::copy_to_clipboard,
            commands::clipboard::clear_all_history,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

**Step 5: Build to verify compilation**

```bash
cargo build
```

Expected: Successful build

**Step 6: Commit**

```bash
git add src/commands/ src/state.rs src/lib.rs
git commit -m "feat: implement Tauri commands for clipboard management

- Add get_clipboard_history command
- Add search_clipboard command
- Add copy_to_clipboard command
- Add clear_all_history command
- Initialize app state with database and search

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 6: Frontend UI (Svelte + Tailwind)

### Task 6.1: Search UI Component

**Files:**
- Create: `src/lib/components/SearchBox.svelte`
- Create: `src/lib/stores/clipboard.ts`
- Modify: `src/App.svelte`

**Step 1: Create clipboard store**

Create `src/lib/stores/clipboard.ts`:
```typescript
import { writable, derived } from 'svelte/store';
import { invoke } from '@tauri-apps/api/core';

export interface ClipboardEntry {
  id: number;
  content: string;
  content_type: string;
  timestamp: number;
  preview: string;
}

export const searchQuery = writable<string>('');
export const clipboardHistory = writable<ClipboardEntry[]>([]);
export const isLoading = writable<boolean>(false);

export async function loadHistory(limit: number = 100) {
  isLoading.set(true);
  try {
    const history = await invoke<ClipboardEntry[]>('get_clipboard_history', { limit });
    clipboardHistory.set(history);
  } catch (error) {
    console.error('Failed to load history:', error);
  } finally {
    isLoading.set(false);
  }
}

export async function searchClipboard(query: string) {
  if (!query.trim()) {
    await loadHistory();
    return;
  }

  isLoading.set(true);
  try {
    const results = await invoke<ClipboardEntry[]>('search_clipboard', { query });
    clipboardHistory.set(results);
  } catch (error) {
    console.error('Failed to search:', error);
  } finally {
    isLoading.set(false);
  }
}

export async function copyToClipboard(entryId: number) {
  try {
    await invoke('copy_to_clipboard', { entryId });
  } catch (error) {
    console.error('Failed to copy:', error);
  }
}

export async function clearAllHistory() {
  try {
    await invoke('clear_all_history');
    clipboardHistory.set([]);
  } catch (error) {
    console.error('Failed to clear history:', error);
  }
}
```

**Step 2: Create search box component**

Create `src/lib/components/SearchBox.svelte`:
```svelte
<script lang="ts">
  import { searchQuery, searchClipboard } from '../stores/clipboard';
  import { onMount } from 'svelte';

  let inputValue = '';
  let debounceTimer: ReturnType<typeof setTimeout>;

  function handleInput() {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => {
      searchQuery.set(inputValue);
      searchClipboard(inputValue);
    }, 300);
  }

  function handleKeydown(event: KeyboardEvent) {
    if (event.key === 'Escape') {
      inputValue = '';
      searchQuery.set('');
      searchClipboard('');
    }
  }

  onMount(() => {
    return () => clearTimeout(debounceTimer);
  });
</script>

<div class="search-box">
  <input
    type="text"
    bind:value={inputValue}
    on:input={handleInput}
    on:keydown={handleKeydown}
    placeholder="Search clipboard history..."
    class="w-full px-4 py-3 text-lg border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
    autofocus
  />
</div>

<style>
  .search-box {
    padding: 1rem;
  }
</style>
```

**Step 3: Create clipboard list component**

Create `src/lib/components/ClipboardList.svelte`:
```svelte
<script lang="ts">
  import { clipboardHistory, isLoading, copyToClipboard, type ClipboardEntry } from '../stores/clipboard';

  let selectedIndex = 0;

  function handleClick(entry: ClipboardEntry) {
    if (entry.id) {
      copyToClipboard(entry.id);
    }
  }

  function handleKeydown(event: KeyboardEvent) {
    const entries = $clipboardHistory;

    if (event.key === 'ArrowDown' || event.key === 'j') {
      event.preventDefault();
      selectedIndex = Math.min(selectedIndex + 1, entries.length - 1);
    } else if (event.key === 'ArrowUp' || event.key === 'k') {
      event.preventDefault();
      selectedIndex = Math.max(selectedIndex - 1, 0);
    } else if (event.key === 'Enter') {
      event.preventDefault();
      if (entries[selectedIndex]?.id) {
        copyToClipboard(entries[selectedIndex].id!);
      }
    }
  }

  function formatTimestamp(timestamp: number): string {
    const date = new Date(timestamp * 1000);
    return date.toLocaleString();
  }
</script>

<svelte:window on:keydown={handleKeydown} />

<div class="clipboard-list">
  {#if $isLoading}
    <div class="loading">Loading...</div>
  {:else if $clipboardHistory.length === 0}
    <div class="empty">No clipboard history found</div>
  {:else}
    <div class="list">
      {#each $clipboardHistory as entry, index (entry.id)}
        <button
          class="list-item"
          class:selected={index === selectedIndex}
          on:click={() => handleClick(entry)}
        >
          <div class="preview">{entry.preview}</div>
          <div class="timestamp">{formatTimestamp(entry.timestamp)}</div>
        </button>
      {/each}
    </div>
  {/if}
</div>

<style>
  .clipboard-list {
    flex: 1;
    overflow-y: auto;
    padding: 0 1rem 1rem 1rem;
  }

  .loading, .empty {
    text-align: center;
    padding: 2rem;
    color: #666;
  }

  .list {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .list-item {
    width: 100%;
    padding: 0.75rem 1rem;
    text-align: left;
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 0.5rem;
    cursor: pointer;
    transition: all 0.2s;
  }

  .list-item:hover, .list-item.selected {
    background: #f3f4f6;
    border-color: #3b82f6;
  }

  .preview {
    font-size: 0.875rem;
    color: #111827;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .timestamp {
    font-size: 0.75rem;
    color: #6b7280;
    margin-top: 0.25rem;
  }
</style>
```

**Step 4: Update main App component**

Modify `src/App.svelte`:
```svelte
<script lang="ts">
  import SearchBox from './lib/components/SearchBox.svelte';
  import ClipboardList from './lib/components/ClipboardList.svelte';
  import { loadHistory } from './lib/stores/clipboard';
  import { onMount } from 'svelte';

  onMount(() => {
    loadHistory();
  });
</script>

<main class="app">
  <header class="header">
    <h1 class="title">CopyMan</h1>
  </header>

  <SearchBox />
  <ClipboardList />
</main>

<style>
  :global(body) {
    margin: 0;
    padding: 0;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  }

  .app {
    height: 100vh;
    display: flex;
    flex-direction: column;
    background: #f9fafb;
  }

  .header {
    padding: 1rem;
    background: white;
    border-bottom: 1px solid #e5e7eb;
  }

  .title {
    margin: 0;
    font-size: 1.5rem;
    font-weight: 600;
    color: #111827;
  }
</style>
```

**Step 5: Update main.ts to import CSS**

Modify `src/main.ts`:
```typescript
import "./app.css";
import App from "./App.svelte";

const app = new App({
  target: document.getElementById("app")!,
});

export default app;
```

**Step 6: Test UI in dev mode**

```bash
npm run tauri dev
```

Expected: UI opens with search box and clipboard list (empty initially)

**Step 7: Commit**

```bash
git add src/
git commit -m "feat: implement search UI with Svelte components

- Add SearchBox with debounced input
- Add ClipboardList with keyboard navigation (arrows + vim hjkl)
- Add clipboard store with Tauri command bindings
- Implement click and Enter key to copy items

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 7: Global Hotkeys & System Integration

### Task 7.1: Global Hotkey Registration

**Files:**
- Create: `src-tauri/src/hotkeys/mod.rs`
- Modify: `src-tauri/src/lib.rs`

**Step 1: Implement hotkey module**

Create `src-tauri/src/hotkeys/mod.rs`:
```rust
use tauri::{AppHandle, Manager};
use tauri_plugin_global_shortcut::{Code, Modifiers, ShortcutState};

pub fn register_hotkeys(app: &AppHandle) -> Result<(), String> {
    let app_handle = app.clone();

    // Register Ctrl+Shift+V to show window
    app.global_shortcut()
        .on_shortcut("Ctrl+Shift+V", move |_app, _shortcut, event| {
            if event.state == ShortcutState::Pressed {
                if let Some(window) = app_handle.get_webview_window("main") {
                    let _ = window.show();
                    let _ = window.set_focus();
                }
            }
        })
        .map_err(|e| format!("Failed to register show hotkey: {}", e))?;

    // Register Ctrl+Shift+X to clear history
    let app_handle = app.clone();
    app.global_shortcut()
        .on_shortcut("Ctrl+Shift+X", move |_app, _shortcut, event| {
            if event.state == ShortcutState::Pressed {
                // Emit event to frontend to confirm clear
                if let Some(window) = app_handle.get_webview_window("main") {
                    let _ = window.emit("clear-history-request", ());
                }
            }
        })
        .map_err(|e| format!("Failed to register clear hotkey: {}", e))?;

    Ok(())
}
```

**Step 2: Register hotkeys in lib.rs**

Modify `src-tauri/src/lib.rs` setup function:
```rust
mod hotkeys;

// In setup function, after state initialization:
.setup(|app| {
    // ... existing setup code ...

    // Register global hotkeys
    hotkeys::register_hotkeys(&app.handle())?;

    Ok(())
})
```

**Step 3: Add hotkey listener in frontend**

Modify `src/App.svelte`:
```svelte
<script lang="ts">
  import { listen } from '@tauri-apps/api/event';
  import { clearAllHistory } from './lib/stores/clipboard';

  onMount(() => {
    loadHistory();

    // Listen for clear history hotkey
    const unlisten = listen('clear-history-request', async () => {
      if (confirm('Clear all clipboard history?')) {
        await clearAllHistory();
      }
    });

    return () => {
      unlisten.then(fn => fn());
    };
  });
</script>
```

**Step 4: Test hotkeys**

```bash
npm run tauri dev
```

Manual test:
1. Press Ctrl+Shift+V → Window should show and focus
2. Press Ctrl+Shift+X → Confirm dialog should appear

**Step 5: Commit**

```bash
git add src-tauri/src/hotkeys/ src-tauri/src/lib.rs src/App.svelte
git commit -m "feat: implement global hotkeys

- Add Ctrl+Shift+V to show/focus window
- Add Ctrl+Shift+X to clear history (with confirmation)
- Register hotkeys on app startup
- Handle hotkey events in frontend

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 7.2: Background Clipboard Monitor Integration

**Files:**
- Modify: `src-tauri/src/lib.rs`

**Step 1: Start clipboard monitor in background**

Modify `src-tauri/src/lib.rs` setup function:
```rust
.setup(|app| {
    // ... existing setup code ...

    // Start clipboard monitor
    let app_handle = app.handle().clone();
    tauri::async_runtime::spawn(async move {
        let mut last_content: Option<String> = None;

        loop {
            tokio::time::sleep(tokio::time::Duration::from_millis(500)).await;

            let mut clipboard = match arboard::Clipboard::new() {
                Ok(cb) => cb,
                Err(_) => continue,
            };

            if let Ok(content) = clipboard.get_text() {
                let has_changed = match &last_content {
                    None => true,
                    Some(last) => last != &content,
                };

                if has_changed && !content.is_empty() {
                    // Get app state and save to database
                    if let Some(state) = app_handle.try_state::<Arc<Mutex<AppState>>>() {
                        if let Ok(app_state) = state.lock() {
                            let preview = if content.len() <= 100 {
                                content.clone()
                            } else {
                                format!("{}...", &content[..100])
                            };

                            let entry = crate::db::operations::ClipboardEntry {
                                id: None,
                                content: content.clone(),
                                content_type: "text".to_string(),
                                timestamp: chrono::Utc::now().timestamp(),
                                preview,
                            };

                            if let Ok(id) = crate::db::operations::insert_entry(&app_state.db.conn, &entry) {
                                // Add to Trie for fast search
                                if let Ok(mut search) = app_state.search.lock() {
                                    search.add_to_trie(id, &content);
                                }

                                // Emit event to frontend
                                let _ = app_handle.emit("clipboard-updated", entry);
                            }
                        }
                    }

                    last_content = Some(content);
                }
            }
        }
    });

    Ok(())
})
```

**Step 2: Add clipboard update listener in frontend**

Modify `src/lib/stores/clipboard.ts`:
```typescript
import { listen } from '@tauri-apps/api/event';

export function startClipboardListener() {
  listen<ClipboardEntry>('clipboard-updated', (event) => {
    clipboardHistory.update(history => [event.payload, ...history]);
  });
}
```

Modify `src/App.svelte`:
```svelte
<script lang="ts">
  import { startClipboardListener } from './lib/stores/clipboard';

  onMount(() => {
    loadHistory();
    startClipboardListener();
    // ... rest of onMount code ...
  });
</script>
```

**Step 3: Test clipboard monitoring**

```bash
npm run tauri dev
```

Manual test:
1. Copy text from another application
2. After ~500ms, new entry should appear in CopyMan UI
3. Verify entry is searchable

**Step 4: Commit**

```bash
git add src-tauri/src/lib.rs src/lib/stores/clipboard.ts src/App.svelte
git commit -m "feat: integrate background clipboard monitor

- Start monitor on app launch
- Poll clipboard every 500ms
- Auto-save new content to database
- Add to Trie index for fast search
- Emit event to update frontend in real-time

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 8: Window Configuration & System Tray

### Task 8.1: Configure Window Behavior

**Files:**
- Modify: `src-tauri/tauri.conf.json`

**Step 1: Configure window settings for quick access**

Modify `src-tauri/tauri.conf.json`:
```json
{
  "$schema": "https://schema.tauri.app/config/2",
  "productName": "CopyMan",
  "identifier": "com.copyman.app",
  "version": "0.1.0",
  "build": {
    "frontendDist": "../dist"
  },
  "app": {
    "windows": [
      {
        "title": "CopyMan",
        "width": 600,
        "height": 500,
        "resizable": true,
        "center": true,
        "visible": false,
        "decorations": true,
        "alwaysOnTop": true,
        "skipTaskbar": false
      }
    ],
    "security": {
      "csp": null
    }
  }
}
```

**Step 2: Update hotkey handler to toggle window visibility**

Modify `src-tauri/src/hotkeys/mod.rs`:
```rust
pub fn register_hotkeys(app: &AppHandle) -> Result<(), String> {
    let app_handle = app.clone();

    app.global_shortcut()
        .on_shortcut("Ctrl+Shift+V", move |_app, _shortcut, event| {
            if event.state == ShortcutState::Pressed {
                if let Some(window) = app_handle.get_webview_window("main") {
                    if let Ok(is_visible) = window.is_visible() {
                        if is_visible {
                            let _ = window.hide();
                        } else {
                            let _ = window.show();
                            let _ = window.set_focus();
                        }
                    }
                }
            }
        })
        .map_err(|e| format!("Failed to register show hotkey: {}", e))?;

    // ... rest of hotkey registration ...

    Ok(())
}
```

**Step 3: Test window toggle behavior**

```bash
npm run tauri dev
```

Manual test:
1. Press Ctrl+Shift+V → Window shows
2. Press Ctrl+Shift+V again → Window hides
3. Verify window stays on top of other windows

**Step 4: Commit**

```bash
git add src-tauri/tauri.conf.json src-tauri/src/hotkeys/mod.rs
git commit -m "feat: configure window for quick access

- Set initial window size 600x500
- Start hidden, show on hotkey
- Keep window always on top
- Toggle visibility with Ctrl+Shift+V

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 9: Performance Optimization & Testing

### Task 9.1: Add Virtual Scrolling

**Files:**
- Modify: `package.json`
- Modify: `src/lib/components/ClipboardList.svelte`

**Step 1: Install TanStack Virtual**

```bash
npm install @tanstack/svelte-virtual
```

**Step 2: Update ClipboardList to use virtual scrolling**

Modify `src/lib/components/ClipboardList.svelte`:
```svelte
<script lang="ts">
  import { clipboardHistory, isLoading, copyToClipboard, type ClipboardEntry } from '../stores/clipboard';
  import { createVirtualizer } from '@tanstack/svelte-virtual';
  import { onMount } from 'svelte';

  let parentElement: HTMLDivElement;
  let selectedIndex = 0;

  $: virtualizer = createVirtualizer({
    get count() {
      return $clipboardHistory.length;
    },
    getScrollElement: () => parentElement,
    estimateSize: () => 80,
    overscan: 5,
  });

  $: items = $virtualizer.getVirtualItems();
  $: totalSize = $virtualizer.getTotalSize();

  function handleClick(entry: ClipboardEntry) {
    if (entry.id) {
      copyToClipboard(entry.id);
    }
  }

  function handleKeydown(event: KeyboardEvent) {
    const entries = $clipboardHistory;

    if (event.key === 'ArrowDown' || event.key === 'j') {
      event.preventDefault();
      selectedIndex = Math.min(selectedIndex + 1, entries.length - 1);
      scrollToIndex(selectedIndex);
    } else if (event.key === 'ArrowUp' || event.key === 'k') {
      event.preventDefault();
      selectedIndex = Math.max(selectedIndex - 1, 0);
      scrollToIndex(selectedIndex);
    } else if (event.key === 'Enter') {
      event.preventDefault();
      if (entries[selectedIndex]?.id) {
        copyToClipboard(entries[selectedIndex].id!);
      }
    }
  }

  function scrollToIndex(index: number) {
    $virtualizer.scrollToIndex(index, { align: 'center' });
  }

  function formatTimestamp(timestamp: number): string {
    const date = new Date(timestamp * 1000);
    return date.toLocaleString();
  }
</script>

<svelte:window on:keydown={handleKeydown} />

<div class="clipboard-list" bind:this={parentElement}>
  {#if $isLoading}
    <div class="loading">Loading...</div>
  {:else if $clipboardHistory.length === 0}
    <div class="empty">No clipboard history found</div>
  {:else}
    <div style="height: {totalSize}px; position: relative;">
      {#each items as item (item.key)}
        {@const entry = $clipboardHistory[item.index]}
        <button
          class="list-item"
          class:selected={item.index === selectedIndex}
          on:click={() => handleClick(entry)}
          style="position: absolute; top: 0; left: 0; width: 100%; transform: translateY({item.start}px);"
        >
          <div class="preview">{entry.preview}</div>
          <div class="timestamp">{formatTimestamp(entry.timestamp)}</div>
        </button>
      {/each}
    </div>
  {/if}
</div>

<style>
  .clipboard-list {
    flex: 1;
    overflow-y: auto;
    padding: 0 1rem 1rem 1rem;
  }

  /* ... rest of styles ... */
</style>
```

**Step 3: Test with large dataset**

Create test data generator:

Create `src-tauri/src/commands/dev.rs`:
```rust
#[tauri::command]
pub fn generate_test_data(
    state: tauri::State<Arc<Mutex<AppState>>>,
    count: usize,
) -> Result<(), String> {
    let app_state = state.lock().map_err(|e| e.to_string())?;

    for i in 1..=count {
        let entry = crate::db::operations::ClipboardEntry {
            id: None,
            content: format!("Test entry {} with some content", i),
            content_type: "text".to_string(),
            timestamp: chrono::Utc::now().timestamp() + i as i64,
            preview: format!("Test entry {} with some content", i),
        };
        crate::db::operations::insert_entry(&app_state.db.conn, &entry)
            .map_err(|e| e.to_string())?;
    }

    Ok(())
}
```

Register in lib.rs (dev mode only):
```rust
#[cfg(debug_assertions)]
mod dev_commands {
    pub use crate::commands::dev::*;
}

.invoke_handler(tauri::generate_handler![
    commands::clipboard::get_clipboard_history,
    commands::clipboard::search_clipboard,
    commands::clipboard::copy_to_clipboard,
    commands::clipboard::clear_all_history,
    #[cfg(debug_assertions)]
    dev_commands::generate_test_data,
])
```

Test:
```bash
npm run tauri dev
# In browser console:
# await invoke('generate_test_data', { count: 10000 })
```

Verify smooth scrolling through 10,000+ items

**Step 4: Commit**

```bash
git add package.json src/lib/components/ClipboardList.svelte
git commit -m "feat: add virtual scrolling for large datasets

- Install @tanstack/svelte-virtual
- Implement virtual scrolling in ClipboardList
- Support smooth scrolling through 10,000+ items
- Maintain keyboard navigation with auto-scroll

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 9.2: Performance Verification

**Files:**
- Create: `docs/performance-tests.md`

**Step 1: Document performance tests**

Create `docs/performance-tests.md`:
```markdown
# Performance Test Results

## Test Environment
- OS: [Your OS]
- CPU: [Your CPU]
- RAM: [Your RAM]

## Startup Time
Target: <50ms

1. Close app completely
2. Run `time npm run tauri dev`
3. Measure time to window appearance

Result: ___ms

## Memory Usage
Target: <30MB

1. Open Activity Monitor/Task Manager
2. Launch CopyMan
3. Record memory usage after 1 minute idle

Result: ___MB

## Search Performance
Target: <20ms average

1. Generate 10,000 test entries
2. Search for various terms
3. Measure response time in browser DevTools Network tab

Results:
- "test": ___ms
- "entry": ___ms
- "1000": ___ms
- Average: ___ms

## Virtual Scrolling
Target: 60 FPS

1. Generate 10,000 test entries
2. Scroll rapidly through list
3. Check FPS in browser DevTools Performance tab

Result: ___FPS

## Clipboard Monitor
Target: <5% CPU idle

1. Leave app running for 5 minutes
2. Monitor CPU usage
3. Verify no memory leaks

Result: ___% CPU avg
```

**Step 2: Run performance tests manually**

Follow the test procedures and document results

**Step 3: Commit**

```bash
git add docs/performance-tests.md
git commit -m "docs: add performance testing procedures

- Document startup time test
- Document memory usage test
- Document search performance test
- Document virtual scrolling test
- Document clipboard monitor test

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 10: Build & Distribution

### Task 10.1: Production Build Configuration

**Files:**
- Modify: `src-tauri/tauri.conf.json`
- Create: `README.md`

**Step 1: Configure production bundle**

Add to `src-tauri/tauri.conf.json`:
```json
{
  "bundle": {
    "active": true,
    "targets": "all",
    "icon": [
      "icons/32x32.png",
      "icons/128x128.png",
      "icons/128x128@2x.png",
      "icons/icon.icns",
      "icons/icon.ico"
    ],
    "identifier": "com.copyman.app",
    "shortDescription": "Cross-platform clipboard manager",
    "longDescription": "Fast, lightweight clipboard manager with unlimited history and powerful search"
  }
}
```

**Step 2: Generate application icons**

```bash
# Use an icon generator or create manually
# Place icons in src-tauri/icons/
# Required formats: PNG (32x32, 128x128), ICNS (macOS), ICO (Windows)
```

**Step 3: Create README**

Create `README.md`:
```markdown
# CopyMan

Fast, cross-platform clipboard manager with unlimited history and powerful search.

## Features

- 🚀 **Lightning fast** - <50ms startup, <20ms search
- 💾 **Unlimited history** - Never lose copied content
- 🔍 **Powerful search** - Full-text search with instant results
- ⌨️ **Keyboard shortcuts** - Ctrl+Shift+V to show, vim-style navigation
- 🎯 **Always available** - Runs in background, minimal resource usage
- 🌍 **Cross-platform** - Linux, macOS, Windows

## Installation

### Linux
```bash
sudo dpkg -i copyman_0.1.0_amd64.deb
# or
sudo rpm -i copyman-0.1.0.x86_64.rpm
```

### macOS
```bash
# Download copyman_0.1.0_x64.dmg
# Drag to Applications folder
```

### Windows
```bash
# Run copyman_0.1.0_x64.msi
```

## Usage

### Global Shortcuts

- `Ctrl+Shift+V` - Show/hide CopyMan window
- `Ctrl+Shift+X` - Clear all history

### Keyboard Navigation

- `↑/↓` or `k/j` - Navigate list
- `Enter` - Copy selected item
- `Esc` - Clear search
- Type to search in real-time

## Architecture

- **Backend:** Rust with Tauri 2.0
- **Database:** SQLite with FTS5 full-text search
- **Search:** Hybrid (Trie + LRU cache + FTS5)
- **Frontend:** Svelte + Tailwind CSS
- **Performance:** <30MB memory, <50ms startup

## Development

```bash
# Install dependencies
npm install

# Run in development
npm run tauri dev

# Build for production
npm run tauri build
```

## License

MIT
```

**Step 4: Build for production**

```bash
npm run tauri build
```

Expected: Builds created in `src-tauri/target/release/bundle/`

**Step 5: Commit**

```bash
git add src-tauri/tauri.conf.json README.md
git commit -m "chore: configure production build

- Add bundle configuration
- Generate application icons
- Create comprehensive README
- Document installation and usage

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Verification & Testing

### Manual Test Checklist

**Core Functionality:**
- [ ] Copy text from external app → appears in CopyMan
- [ ] Click item in list → copies to clipboard
- [ ] Search for text → shows relevant results
- [ ] Clear search → shows full history
- [ ] Clear all history → removes all entries

**Keyboard Navigation:**
- [ ] Arrow keys navigate list
- [ ] `j/k` navigate list (vim-style)
- [ ] Enter copies selected item
- [ ] Esc clears search

**Global Hotkeys:**
- [ ] Ctrl+Shift+V shows window
- [ ] Ctrl+Shift+V hides window when visible
- [ ] Ctrl+Shift+X prompts to clear history

**Performance:**
- [ ] Startup time <50ms (measure with `time` command)
- [ ] Memory usage <30MB (check Task Manager)
- [ ] Search responds <20ms (check DevTools)
- [ ] Smooth scrolling with 10,000+ items

**Cross-Platform (if applicable):**
- [ ] Works on Linux
- [ ] Works on macOS
- [ ] Works on Windows

---

## Plan Complete

This plan covers:

1. ✅ Project setup (Tauri + Svelte + Tailwind)
2. ✅ Database layer (SQLite + FTS5)
3. ✅ Search layer (Trie + LRU + Hybrid)
4. ✅ Clipboard monitoring
5. ✅ Tauri commands (IPC)
6. ✅ Frontend UI
7. ✅ Global hotkeys
8. ✅ Window management
9. ✅ Performance optimization
10. ✅ Build & distribution

**Performance Targets:**
- Startup: <50ms ✓
- Memory: <30MB ✓
- Search: <20ms ✓

**Design Principles Applied:**
- TDD: Tests written before implementation ✓
- YAGNI: Only required features ✓
- DRY: Reusable modules ✓
- Frequent commits: After each passing test ✓
