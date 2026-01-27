#[tauri::command]
pub fn hide_window(window: tauri::WebviewWindow) -> Result<(), String> {
    println!("⬇️  HIDE_WINDOW: Called from frontend");
    window.hide().map_err(|e| format!("Failed to hide window: {}", e))?;
    println!("👁️  HIDE_WINDOW: Window hidden");
    // Update our state tracker
    crate::hotkeys::set_window_visible(false);
    println!("✅ HIDE_WINDOW: State updated to false");
    Ok(())
}


#[tauri::command]
pub fn position_window_near_cursor(window: tauri::WebviewWindow) -> Result<(), String> {
    crate::tray::position_window_near_cursor(&window)
}

pub fn show_and_focus_window(window: &tauri::WebviewWindow) -> Result<(), String> {
    println!("⬆️  SHOW_AND_FOCUS_WINDOW: Starting...");

    // Show window
    window.show().map_err(|e| format!("Failed to show window: {}", e))?;
    println!("👁️  SHOW_AND_FOCUS_WINDOW: Window shown");

    // Update our state tracker
    crate::hotkeys::set_window_visible(true);
    println!("✅ SHOW_AND_FOCUS_WINDOW: State updated to true");

    // Position window
    let _ = crate::tray::position_window_near_cursor(window);

    // Immediately request focus
    window.set_focus().map_err(|e| format!("Failed to set focus: {}", e))?;
    println!("🎯 SHOW_AND_FOCUS_WINDOW: Initial focus requested");

    // On Linux, request attention from window manager
    #[cfg(target_os = "linux")]
    let _ = window.request_user_attention(Some(tauri::UserAttentionType::Informational));

    // Also try setting focus multiple times with delays to handle timing issues (especially on Linux/Wayland)
    // This logic was previously duplicated in tray and hotkeys handlers
    let window_clone = window.clone();
    std::thread::spawn(move || {
        use tauri::Emitter; // Import Emitter trait for emit method

        println!("🕐 FOCUS THREAD: Starting delayed focus attempts");

        // Try at different intervals
        std::thread::sleep(std::time::Duration::from_millis(10));
        let _ = window_clone.set_focus();
        println!("🎯 FOCUS THREAD: Focus attempt 1 (10ms)");

        std::thread::sleep(std::time::Duration::from_millis(40));
        let _ = window_clone.set_focus();
        println!("🎯 FOCUS THREAD: Focus attempt 2 (50ms total)");

        // Emit event to trigger focus on search input in frontend
        // This is CRUCIAL: Global shortcuts were missing this!
        let _ = window_clone.emit("window-focused", ());
        println!("📢 FOCUS THREAD: Emitted window-focused event");

        std::thread::sleep(std::time::Duration::from_millis(50));
        let _ = window_clone.set_focus();
        println!("🎯 FOCUS THREAD: Focus attempt 3 (100ms total) - DONE");
    });

    Ok(())
}
