use tauri::{AppHandle, Manager, Emitter};
use tauri_plugin_global_shortcut::{GlobalShortcutExt, ShortcutState};
use crate::settings::Settings;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

static WINDOW_IS_VISIBLE: AtomicBool = AtomicBool::new(false);
static LAST_TOGGLE_TIME: AtomicU64 = AtomicU64::new(0);

fn get_now_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as u64
}

// Helper functions to manage window visibility state
pub fn set_window_visible(visible: bool) {
    println!("🔄 STATE CHANGE: Setting window_visible to {} (was: {})", visible, WINDOW_IS_VISIBLE.load(Ordering::Relaxed));
    WINDOW_IS_VISIBLE.store(visible, Ordering::Relaxed);
    LAST_TOGGLE_TIME.store(get_now_ms(), Ordering::Relaxed);
    println!("✅ STATE CONFIRMED: window_visible is now {}", WINDOW_IS_VISIBLE.load(Ordering::Relaxed));
}

pub fn is_window_visible() -> bool {
    let state = WINDOW_IS_VISIBLE.load(Ordering::Relaxed);
    println!("🔍 STATE CHECK: is_window_visible() = {}", state);
    state
}

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
                let now = get_now_ms();
                let last = LAST_TOGGLE_TIME.load(Ordering::Relaxed);
                
                // Debounce: If less than 300ms since last action, ignore
                // This prevents race condition where frontend handles keydown first, hides window,
                // and then this global shortcut listener fires seeing state as hidden and tries to show it
                if now.saturating_sub(last) < 300 {
                    println!("⏳ DEBOUNCE: Hotkey ignored ({}ms since last action)", now.saturating_sub(last));
                    return;
                }

                if let Some(window) = app_handle.get_webview_window("main") {
                    // Use our state tracker instead of is_visible() which is unreliable on Wayland
                    let is_visible = is_window_visible();
                    let tauri_visible = window.is_visible().unwrap_or(false);
                    println!("Hotkey pressed - tracked state: {}, tauri is_visible: {}", is_visible, tauri_visible);

                    if is_visible {
                        println!("Hiding window via hotkey");
                        // Emit event to frontend to set isHiding flag BEFORE hiding
                        let _ = window.emit("intentional-hide", ());
                        // Small delay to ensure event is processed
                        std::thread::sleep(std::time::Duration::from_millis(10));
                        let _ = window.hide();
                        // Update our state tracker
                        set_window_visible(false);
                    } else {
                        println!("Showing window via hotkey");
                        let _ = crate::commands::window::show_and_focus_window(&window);
                        // State is updated inside show_and_focus_window
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
