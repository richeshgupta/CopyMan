#[tauri::command]
pub fn hide_window(window: tauri::WebviewWindow) -> Result<(), String> {
    window.hide().map_err(|e| format!("Failed to hide window: {}", e))?;
    Ok(())
}

#[tauri::command]
pub fn position_window_near_cursor(window: tauri::WebviewWindow) -> Result<(), String> {
    crate::tray::position_window_near_cursor(&window)
}
