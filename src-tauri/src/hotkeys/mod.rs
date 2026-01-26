use tauri::{AppHandle, Manager, Emitter};
use tauri_plugin_global_shortcut::{GlobalShortcutExt, ShortcutState};
use crate::settings::Settings;

pub fn register_hotkeys(app: &AppHandle) -> Result<(), String> {
    // Load settings and register with those hotkeys
    let app_dir = app.path().app_data_dir()
        .map_err(|e| format!("Failed to get app data directory: {}", e))?;
    let settings_path = app_dir.join("settings.json");
    let settings = Settings::load(&settings_path)?;

    register_hotkeys_with_settings(app, &settings)
}

pub fn register_hotkeys_with_settings(app: &AppHandle, settings: &Settings) -> Result<(), String> {
    let app_handle = app.clone();
    let show_hide_key = settings.hotkeys.show_hide.clone();

    // Register show/hide window hotkey
    app.global_shortcut()
        .on_shortcut(show_hide_key.as_str(), move |_app, _shortcut, event| {
            if event.state == ShortcutState::Pressed {
                if let Some(window) = app_handle.get_webview_window("main") {
                    if let Ok(is_visible) = window.is_visible() {
                        if is_visible {
                            let _ = window.hide();
                        } else {
                            let _ = window.show();
                            let _ = window.set_focus();
                            // Position window near tray icon
                            let _ = crate::tray::position_window_near_cursor(&window);
                        }
                    }
                }
            }
        })
        .map_err(|e| format!("Failed to register show hotkey: {}", e))?;

    // Register clear history hotkey
    let app_handle = app.clone();
    let clear_key = settings.hotkeys.clear_history.clone();

    app.global_shortcut()
        .on_shortcut(clear_key.as_str(), move |_app, _shortcut, event| {
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

pub fn unregister_hotkeys(app: &AppHandle) -> Result<(), String> {
    // Unregister all shortcuts
    app.global_shortcut()
        .unregister_all()
        .map_err(|e| format!("Failed to unregister hotkeys: {}", e))?;

    Ok(())
}
