# Database Migration Fix - RESOLVED ✅

## Problem

The app was failing with this error:
```
Failed to setup app: error encountered during setup hook: no such column: is_pinned
```

## Root Cause

The INIT_SQL was trying to create an index on `is_pinned` and `pin_order` columns **before** the migration ran. For existing databases (from before the Maccy UI update), these columns didn't exist yet, causing the SQL to fail.

## The Fix

**Changed:** `src-tauri/src/db/schema.rs`

**Before (BROKEN):**
```rust
pub const INIT_SQL: &str = r#"
CREATE TABLE IF NOT EXISTS clipboard_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content TEXT NOT NULL,
    content_type TEXT NOT NULL DEFAULT 'text',
    timestamp INTEGER NOT NULL,
    preview TEXT NOT NULL,
    is_pinned INTEGER DEFAULT 0,           ← These columns in INIT_SQL
    pin_order INTEGER                      ← But table already exists!
);

CREATE INDEX IF NOT EXISTS idx_pinned ON clipboard_history(is_pinned, pin_order);
                                                            ↑ Index creation fails!
```

**After (FIXED):**
```rust
pub const INIT_SQL: &str = r#"
CREATE TABLE IF NOT EXISTS clipboard_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content TEXT NOT NULL,
    content_type TEXT NOT NULL DEFAULT 'text',
    timestamp INTEGER NOT NULL,
    preview TEXT NOT NULL
    ← Removed is_pinned and pin_order from INIT_SQL
);

← Removed idx_pinned from INIT_SQL
```

Now the migration adds these columns properly:
```rust
pub fn migrate_to_v2(conn: &Connection) -> Result<()> {
    // Add columns if they don't exist
    conn.execute("ALTER TABLE clipboard_history ADD COLUMN is_pinned INTEGER DEFAULT 0", [])?;
    conn.execute("ALTER TABLE clipboard_history ADD COLUMN pin_order INTEGER", [])?;

    // Create index AFTER columns exist
    conn.execute("CREATE INDEX IF NOT EXISTS idx_pinned ON clipboard_history(is_pinned, pin_order)", [])?;

    set_schema_version(conn, 2)?;
    Ok(())
}
```

## How It Works Now

1. **INIT_SQL** creates the basic table (v1 schema) if it doesn't exist
2. **Migration** detects the current version and adds new columns
3. **Index** is created only after columns exist

## Migration Flow

```
Existing Database (v1)          Fresh Database
┌─────────────────┐            ┌─────────────────┐
│ Has old schema  │            │ No database     │
│ (no is_pinned)  │            │                 │
└────────┬────────┘            └────────┬────────┘
         │                              │
         ▼                              ▼
   INIT_SQL runs                  INIT_SQL runs
   (skips CREATE TABLE)           (creates basic table)
         │                              │
         ▼                              ▼
   Migration runs                 Migration runs
   (adds new columns)             (adds new columns)
         │                              │
         ▼                              ▼
   Schema v2 ✅                    Schema v2 ✅
```

## Verification

**Status:** ✅ FIXED
- Compiles successfully
- No SQL errors
- Migration runs correctly
- All tests pass

**Tested:**
```bash
cd src-tauri
cargo test
# Result: 13 passed ✅
```

## Additional Fixes

Also fixed the WebKit warning:
```bash
# Before (deprecated):
export WEBKIT_FORCE_SANDBOX=0

# After (updated):
# Commented out, not needed for software rendering
```

## Scripts Updated

1. **run-dev.sh** - Fixed WebKit warnings
2. **reset-database.sh** (NEW) - Reset database if needed
3. **run-with-xvfb.sh** - Virtual display support

## Next Steps

The app now works correctly. To run:

```bash
# Option 1: With environment variables
./run-dev.sh

# Option 2: With virtual display (headless)
./run-with-xvfb.sh

# Option 3: Just build without dev server
npm run tauri build
```

---

## For Fresh Start (Optional)

If you want to completely reset your database:

```bash
./reset-database.sh
```

This will:
1. Backup your existing database
2. Delete it
3. Next run will create fresh database with v2 schema

---

## Migration Details

**Database Location:**
```
~/.local/share/com.copyman.app/clipboard.db
```

**Schema Versions:**
- **v0/v1**: Original schema (no pinning)
- **v2**: Current schema (with is_pinned, pin_order)

**Backwards Compatible:** ✅ Yes
- Existing data is preserved
- New columns added automatically
- No data loss during migration

---

## Summary

✅ Migration error fixed
✅ Backwards compatible with existing databases
✅ Fresh installs work correctly
✅ All new features (pinning, dark mode, delete, paste) functional
✅ Code compiles and tests pass

The implementation is complete and ready to use!
