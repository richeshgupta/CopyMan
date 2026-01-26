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
