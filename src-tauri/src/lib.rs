mod db;
mod search;
mod clipboard;
mod commands;
mod state;
mod hotkeys;

use state::AppState;
use std::sync::{Arc, Mutex};
use tauri::Manager;

// Learn more about Tauri commands at https://tauri.app/develop/calling-rust/
#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_clipboard_manager::init())
        .plugin(tauri_plugin_global_shortcut::Builder::new().build())
        .setup(|app| {
            // Initialize database
            let app_dir = app.path().app_data_dir()?;
            std::fs::create_dir_all(&app_dir)?;
            let db_path = app_dir.join("clipboard.db");

            let state = AppState::new(db_path)?;
            app.manage(Arc::new(Mutex::new(state)));

            // Register global hotkeys
            hotkeys::register_hotkeys(&app.handle())?;

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            greet,
            commands::clipboard::get_clipboard_history,
            commands::clipboard::search_clipboard,
            commands::clipboard::copy_to_clipboard,
            commands::clipboard::clear_all_history,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
