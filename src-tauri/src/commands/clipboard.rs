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
