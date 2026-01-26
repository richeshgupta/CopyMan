use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HotkeySettings {
    pub show_hide: String,
    pub clear_history: String,
}

impl Default for HotkeySettings {
    fn default() -> Self {
        Self {
            show_hide: "Ctrl+Shift+V".to_string(),
            clear_history: "Ctrl+Shift+X".to_string(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Settings {
    pub hotkeys: HotkeySettings,
}

impl Default for Settings {
    fn default() -> Self {
        Self {
            hotkeys: HotkeySettings::default(),
        }
    }
}

impl Settings {
    pub fn load(path: &PathBuf) -> Result<Self, String> {
        if path.exists() {
            let contents = fs::read_to_string(path)
                .map_err(|e| format!("Failed to read settings file: {}", e))?;

            let settings: Settings = serde_json::from_str(&contents)
                .map_err(|e| format!("Failed to parse settings: {}", e))?;

            Ok(settings)
        } else {
            // Return default settings if file doesn't exist
            Ok(Settings::default())
        }
    }

    pub fn save(&self, path: &PathBuf) -> Result<(), String> {
        let contents = serde_json::to_string_pretty(self)
            .map_err(|e| format!("Failed to serialize settings: {}", e))?;

        // Ensure parent directory exists
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)
                .map_err(|e| format!("Failed to create settings directory: {}", e))?;
        }

        fs::write(path, contents)
            .map_err(|e| format!("Failed to write settings file: {}", e))?;

        Ok(())
    }
}
