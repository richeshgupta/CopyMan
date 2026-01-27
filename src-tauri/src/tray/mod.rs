use tauri::{
    menu::{MenuBuilder, MenuItemBuilder},
    tray::{TrayIconBuilder, TrayIconEvent},
    AppHandle, Manager, Emitter, Runtime,
};

pub fn create_tray(app: &AppHandle) -> Result<(), String> {
    // Build the tray menu
    let show_hide = MenuItemBuilder::with_id("show_hide", "Show/Hide CopyMan").build(app)
        .map_err(|e| format!("Failed to create show/hide menu item: {}", e))?;

    let settings = MenuItemBuilder::with_id("settings", "Settings").build(app)
        .map_err(|e| format!("Failed to create settings menu item: {}", e))?;

    let clear_history = MenuItemBuilder::with_id("clear_history", "Clear History").build(app)
        .map_err(|e| format!("Failed to create clear history menu item: {}", e))?;

    let quit = MenuItemBuilder::with_id("quit", "Quit").build(app)
        .map_err(|e| format!("Failed to create quit menu item: {}", e))?;

    let menu = MenuBuilder::new(app)
        .items(&[&show_hide, &settings, &clear_history, &quit])
        .build()
        .map_err(|e| format!("Failed to build menu: {}", e))?;

    // Create the tray icon
    let _tray = TrayIconBuilder::new()
        .icon(app.default_window_icon().unwrap().clone())
        .menu(&menu)
        .show_menu_on_left_click(false)
        .on_menu_event(move |app, event| {
            match event.id().as_ref() {
                "show_hide" => {
                    if let Some(window) = app.get_webview_window("main") {
                        // Use state tracker instead of is_visible() which is unreliable on Wayland
                        let is_visible = crate::hotkeys::is_window_visible();

                        if is_visible {
                            // Emit event to frontend to set isHiding flag BEFORE hiding
                            let _ = window.emit("intentional-hide", ());
                            // Small delay to ensure event is processed
                            std::thread::sleep(std::time::Duration::from_millis(10));
                            let _ = window.hide();
                            crate::hotkeys::set_window_visible(false);
                        } else {
                            let _ = crate::commands::window::show_and_focus_window(&window);
                            // State is updated inside show_and_focus_window
                        }
                    }
                }
                "settings" => {
                    if let Some(window) = app.get_webview_window("main") {
                        println!("Settings clicked - showing window");
                        let was_visible = window.is_visible().unwrap_or(false);
                        println!("Window was visible: {}", was_visible);

                        let _ = window.show();
                        let _ = window.set_focus();
                        let _ = position_window_near_cursor(&window);

                        // Delay to ensure window and JS are fully ready
                        // Longer delay if window wasn't visible
                        let delay = if was_visible { 50 } else { 200 };
                        let window_clone = window.clone();
                        std::thread::spawn(move || {
                            std::thread::sleep(std::time::Duration::from_millis(delay));
                            println!("About to emit show-settings event");
                            let _ = window_clone.emit("show-settings", ());
                            println!("Emitted show-settings event from Rust");
                        });
                    }
                }
                "clear_history" => {
                    if let Some(window) = app.get_webview_window("main") {
                        let _ = window.emit("clear-history-request", ());
                    }
                }
                "quit" => {
                    app.exit(0);
                }
                _ => {}
            }
        })
        .on_tray_icon_event(|tray, event| {
            if let TrayIconEvent::Click { button, .. } = event {
                if button == tauri::tray::MouseButton::Left {
                    let app = tray.app_handle();
                    if let Some(window) = app.get_webview_window("main") {
                        // Use state tracker instead of is_visible() which is unreliable on Wayland
                        let is_visible = crate::hotkeys::is_window_visible();

                        if is_visible {
                            // Emit event to frontend to set isHiding flag BEFORE hiding
                            let _ = window.emit("intentional-hide", ());
                            // Small delay to ensure event is processed
                            std::thread::sleep(std::time::Duration::from_millis(10));
                            let _ = window.hide();
                            crate::hotkeys::set_window_visible(false);
                        } else {
                            let _ = crate::commands::window::show_and_focus_window(&window);
                            // State is updated inside show_and_focus_window
                        }
                    }
                }
            }
        })
        .build(app)
        .map_err(|e| format!("Failed to create tray icon: {}", e))?;

    Ok(())
}

pub fn position_window_near_cursor<R: Runtime>(window: &tauri::WebviewWindow<R>) -> Result<(), String> {
    position_window_near_tray(window)
}

pub fn position_window_near_tray<R: Runtime>(window: &tauri::WebviewWindow<R>) -> Result<(), String> {
    use tauri::Position;

    // Get the primary monitor
    if let Ok(Some(monitor)) = window.primary_monitor() {
        let monitor_size = monitor.size();
        let window_size = window.outer_size().unwrap_or(tauri::PhysicalSize {
            width: 600,
            height: 500,
        });

        // Position in top-right corner (where tray icon typically is on Linux)
        // Add padding from edges
        let padding = 10;
        let x = monitor_size.width as i32 - window_size.width as i32 - padding;
        let y = padding;

        window.set_position(Position::Physical(tauri::PhysicalPosition { x, y }))
            .map_err(|e| format!("Failed to set window position: {}", e))?;
    }

    Ok(())
}
