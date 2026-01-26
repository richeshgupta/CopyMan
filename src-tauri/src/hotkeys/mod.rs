use tauri::{AppHandle, Manager};
use tauri_plugin_global_shortcut::{Code, Modifiers, ShortcutState};

pub fn register_hotkeys(app: &AppHandle) -> Result<(), String> {
    let app_handle = app.clone();

    // Register Ctrl+Shift+V to show/hide window
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
