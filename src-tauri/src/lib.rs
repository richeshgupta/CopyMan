mod db;
mod search;
mod clipboard;
mod commands;
mod state;
mod hotkeys;
mod tray;
mod settings;
mod paste;

use state::AppState;
use std::sync::{Arc, Mutex};
use tauri::{Manager, Emitter};

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

            // Create system tray
            tray::create_tray(&app.handle())?;

            // Listen for window focus events to sync our internal state
            // This is critical because if the user clicks the window or al-tabs to it,
            // our hotkey toggle logic needs to know it's visible to properly hide it next time.
            if let Some(window) = app.get_webview_window("main") {
                window.on_window_event(move |event| {
                    if let tauri::WindowEvent::Focused(focused) = event {
                        if *focused {
                            println!("🎯 WINDOW EVENT: Focused(true) - Updating internal state");
                            crate::hotkeys::set_window_visible(true);
                        }
                    }
                });
            }

            // Start clipboard monitor
            let app_handle = app.handle().clone();
            tauri::async_runtime::spawn(async move {
                let mut last_content: Option<String> = None;
                
                // Initialize clipboard once, outside the loop
                // Retry a few times if it fails initially (common on startup)
                let clipboard = loop {
                    match arboard::Clipboard::new() {
                        Ok(cb) => break Some(cb),
                        Err(e) => {
                            eprintln!("Failed to initialize clipboard: {}, retrying in 1s...", e);
                            tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
                            // In case of persistent failure, we might want to break or continue retrying
                            // For now, we'll keep retrying indefinitely or until it works
                        }
                    }
                };

                // If we somehow failed to get a clipboard instance (shouldn't happen with loop above), exit task
                if clipboard.is_none() {
                    eprintln!("CRITICAL: Could not initialize clipboard monitor task");
                    return;
                }
                
                let mut clipboard_instance = clipboard.unwrap();

                loop {
                    tokio::time::sleep(tokio::time::Duration::from_millis(500)).await;

                    match clipboard_instance.get_text() {
                        Ok(content) => {
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
                                            is_pinned: false,
                                            pin_order: None,
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
                        },
                        Err(_e) => {
                            // Only log non-transient errors or debounce logging if needed
                            // For now, simple error logging
                            // eprintln!("Error reading clipboard: {}", _e); 
                            // Re-initialization logic could go here if the connection is lost
                        }
                    }
                }
            });

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            greet,
            commands::clipboard::get_clipboard_history,
            commands::clipboard::search_clipboard,
            commands::clipboard::copy_to_clipboard,
            commands::clipboard::clear_all_history,
            commands::clipboard::pin_clipboard_entry,
            commands::clipboard::unpin_clipboard_entry,
            commands::clipboard::delete_clipboard_entry,
            commands::clipboard::get_pinned_clipboard_entries,
            commands::clipboard::paste_clipboard_text,
            commands::window::hide_window,
            commands::window::position_window_near_cursor,
            commands::settings::get_settings,
            commands::settings::save_settings,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
