#[tauri::command]
pub fn hide_window(window: tauri::WebviewWindow) -> Result<(), String> {
    window.hide().map_err(|e| format!("Failed to hide window: {}", e))?;
    Ok(())
}


#[tauri::command]
pub fn position_window_near_cursor(window: tauri::WebviewWindow) -> Result<(), String> {
    crate::tray::position_window_near_cursor(&window)
}

pub fn show_and_focus_window(window: &tauri::WebviewWindow) -> Result<(), String> {
    // Show window
    window.show().map_err(|e| format!("Failed to show window: {}", e))?;
    
    // Position window
    let _ = crate::tray::position_window_near_cursor(window);

    // Immediately request focus
    window.set_focus().map_err(|e| format!("Failed to set focus: {}", e))?;

    // On Linux, request attention from window manager
    #[cfg(target_os = "linux")]
    let _ = window.request_user_attention(Some(tauri::UserAttentionType::Informational));

    // Also try setting focus multiple times with delays to handle timing issues (especially on Linux/Wayland)
    // This logic was previously duplicated in tray and hotkeys handlers
    let window_clone = window.clone();
    std::thread::spawn(move || {
        use tauri::Emitter; // Import Emitter trait for emit method
        
        // Try at different intervals
        std::thread::sleep(std::time::Duration::from_millis(10));
        let _ = window_clone.set_focus();

        std::thread::sleep(std::time::Duration::from_millis(40));
        let _ = window_clone.set_focus();

        // Emit event to trigger focus on search input in frontend
        // This is CRUCIAL: Global shortcuts were missing this!
        let _ = window_clone.emit("window-focused", ());

        std::thread::sleep(std::time::Duration::from_millis(50));
        let _ = window_clone.set_focus();
    });

    Ok(())
}
