use crate::settings::Settings;
use std::path::PathBuf;
use tauri::{AppHandle, Manager};

fn get_settings_path(app: &AppHandle) -> Result<PathBuf, String> {
    let app_dir = app.path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app data directory: {}", e))?;

    Ok(app_dir.join("settings.json"))
}

#[tauri::command]
pub fn get_settings(app: AppHandle) -> Result<Settings, String> {
    let settings_path = get_settings_path(&app)?;
    Settings::load(&settings_path)
}

#[tauri::command]
pub fn save_settings(app: AppHandle, settings: Settings) -> Result<(), String> {
    let settings_path = get_settings_path(&app)?;
    settings.save(&settings_path)?;

    // Re-register hotkeys with new settings
    crate::hotkeys::unregister_hotkeys(&app)?;
    crate::hotkeys::register_hotkeys_with_settings(&app, &settings)?;

    Ok(())
}
