use crate::db::operations::{ClipboardEntry, get_recent_entries, get_entry_by_id, pin_entry, unpin_entry, delete_entry, get_pinned_entries};
use crate::state::AppState;
use crate::paste;
use std::sync::{Arc, Mutex};
use tauri::{State, AppHandle, Manager};

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

    let search = app_state.search
        .lock()
        .map_err(|e| e.to_string())?;

    search.search(&app_state.db.conn, &query)
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

#[tauri::command]
pub fn pin_clipboard_entry(
    state: State<Arc<Mutex<AppState>>>,
    id: i64,
) -> Result<(), String> {
    let app_state = state.lock().map_err(|e| e.to_string())?;
    pin_entry(&app_state.db.conn, id)
        .map_err(|e| format!("Failed to pin entry: {}", e))?;
    Ok(())
}

#[tauri::command]
pub fn unpin_clipboard_entry(
    state: State<Arc<Mutex<AppState>>>,
    id: i64,
) -> Result<(), String> {
    let app_state = state.lock().map_err(|e| e.to_string())?;
    unpin_entry(&app_state.db.conn, id)
        .map_err(|e| format!("Failed to unpin entry: {}", e))?;
    Ok(())
}

#[tauri::command]
pub fn delete_clipboard_entry(
    state: State<Arc<Mutex<AppState>>>,
    id: i64,
) -> Result<(), String> {
    let app_state = state.lock().map_err(|e| e.to_string())?;
    delete_entry(&app_state.db.conn, id)
        .map_err(|e| format!("Failed to delete entry: {}", e))?;
    Ok(())
}

#[tauri::command]
pub fn get_pinned_clipboard_entries(
    state: State<Arc<Mutex<AppState>>>,
) -> Result<Vec<ClipboardEntry>, String> {
    let app_state = state.lock().map_err(|e| e.to_string())?;
    get_pinned_entries(&app_state.db.conn)
        .map_err(|e| format!("Failed to get pinned entries: {}", e))
}

#[tauri::command]
pub async fn paste_clipboard_text(
    text: String,
    app: AppHandle,
) -> Result<(), String> {
    // 1. Hide window first to return focus to previous app
    println!("📋 PASTE_COMMAND: Hiding window before paste");
    if let Some(window) = app.get_webview_window("main") {
        crate::commands::window::hide_window(window)?;
    }
    
    // 2. Wait for focus to switch (essential on Linux/X11)
    println!("⏳ PASTE_COMMAND: Waiting 200ms for focus switch");
    tokio::time::sleep(tokio::time::Duration::from_millis(200)).await;

    // 3. Simulate paste
    println!("⌨️  PASTE_COMMAND: Executing paste");
    paste::paste_text(&app, &text)?;
    Ok(())
}
