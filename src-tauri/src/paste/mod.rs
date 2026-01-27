use tauri::Runtime;

#[cfg(target_os = "macos")]
pub fn paste_text<R: Runtime>(_app: &tauri::AppHandle<R>, text: &str) -> Result<(), String> {
    use std::process::Command;

    // Copy to clipboard first
    arboard::Clipboard::new()
        .and_then(|mut clipboard| clipboard.set_text(text))
        .map_err(|e| format!("Failed to copy: {}", e))?;

    // Simulate Cmd+V using osascript
    Command::new("osascript")
        .arg("-e")
        .arg("tell application \"System Events\" to keystroke \"v\" using command down")
        .output()
        .map_err(|e| format!("Failed to paste: {}", e))?;

    Ok(())
}

#[cfg(target_os = "windows")]
pub fn paste_text<R: Runtime>(_app: &tauri::AppHandle<R>, text: &str) -> Result<(), String> {
    // Copy to clipboard - on Windows, direct paste simulation is complex
    // For now, just copy to clipboard as a fallback
    arboard::Clipboard::new()
        .and_then(|mut clipboard| clipboard.set_text(text))
        .map_err(|e| format!("Failed to copy: {}", e))?;

    // Note: Direct paste would require additional dependencies or PowerShell
    // This is acceptable as the plan mentions graceful degradation
    Ok(())
}

#[cfg(target_os = "linux")]
pub fn paste_text<R: Runtime>(_app: &tauri::AppHandle<R>, text: &str) -> Result<(), String> {
    use std::process::Command;

    // Copy to clipboard
    arboard::Clipboard::new()
        .and_then(|mut clipboard| clipboard.set_text(text))
        .map_err(|e| format!("Failed to copy: {}", e))?;

    // Try xdotool for X11 (ignore errors if not available)
    let _ = Command::new("xdotool")
        .args(&["key", "ctrl+v"])
        .output();

    // Fallback: text is already in clipboard
    Ok(())
}
