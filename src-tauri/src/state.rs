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
