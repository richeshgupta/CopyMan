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

    // Ensure it's not minimized (critical for some WMs)
    window.unminimize().map_err(|e| format!("Failed to unminimize: {}", e))?;

    // Update our state tracker
    crate::hotkeys::set_window_visible(true);
    println!("✅ SHOW_AND_FOCUS_WINDOW: State updated to true");

    // Position window
    let _ = crate::tray::position_window_near_cursor(window);

    // Immediately request focus (optimistic)
    let _ = window.set_focus();

    // On Linux, request attention from window manager
    #[cfg(target_os = "linux")]
    let _ = window.request_user_attention(Some(tauri::UserAttentionType::Informational));

    // Async thread to force focus via Window Manager hacks
    let window_clone = window.clone();
    std::thread::spawn(move || {
        use tauri::Emitter;

        println!("🕐 FOCUS THREAD: Starting aggressive focus sequence");

        // Step 1: Small delay to let show/unminimize propagate
        std::thread::sleep(std::time::Duration::from_millis(50));
        
        // Step 2: Toggle AlwaysOnTop to force Z-order update
        // LINUX FOCUS HACK: This forces the WM to re-evaluate the window's priority
        #[cfg(target_os = "linux")]
        {
            println!("🔒 FOCUS THREAD: Toggling AlwaysOnTop OFF");
            let _ = window_clone.set_always_on_top(false);
            
            // CRITICAL DELAY: Give WM time to process 'lower' state
            std::thread::sleep(std::time::Duration::from_millis(50));
            
            println!("🔓 FOCUS THREAD: Toggling AlwaysOnTop ON");
            let _ = window_clone.set_always_on_top(true);
        }

        // Step 3: Final delay before demanding focus
        std::thread::sleep(std::time::Duration::from_millis(50));
        
        println!("🎯 FOCUS THREAD: Final set_focus()");
        let _ = window_clone.set_focus();

        // Step 4: Emit event to frontend to focus input
        let _ = window_clone.emit("window-focused", ());
        println!("📢 FOCUS THREAD: Emitted window-focused event");
    });

    Ok(())
}
