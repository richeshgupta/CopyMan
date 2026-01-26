use arboard::Clipboard;
use std::time::Duration;
use tokio::time::sleep;

pub struct ClipboardMonitor {
    clipboard: Clipboard,
}

impl ClipboardMonitor {
    pub fn new() -> Self {
        ClipboardMonitor {
            clipboard: Clipboard::new().expect("Failed to initialize clipboard"),
        }
    }

    pub fn read_text(&mut self) -> Result<String, String> {
        self.clipboard
            .get_text()
            .map_err(|e| format!("Failed to read clipboard: {}", e))
    }

    pub fn write_text(&mut self, content: &str) -> Result<(), String> {
        self.clipboard
            .set_text(content)
            .map_err(|e| format!("Failed to write clipboard: {}", e))
    }

    pub fn has_changed(&self, new_content: &str, last_content: &Option<String>) -> bool {
        match last_content {
            None => true,
            Some(last) => last != new_content,
        }
    }

    pub fn generate_preview(&self, content: &str) -> String {
        if content.len() <= 100 {
            content.to_string()
        } else {
            format!("{}...", &content[..100])
        }
    }
}

pub async fn start_monitor<F>(mut callback: F) -> Result<(), String>
where
    F: FnMut(String) + Send + 'static,
{
    let mut monitor = ClipboardMonitor::new();
    let mut last_content: Option<String> = None;

    loop {
        if let Ok(content) = monitor.read_text() {
            if monitor.has_changed(&content, &last_content) {
                callback(content.clone());
                last_content = Some(content);
            }
        }

        sleep(Duration::from_millis(500)).await;
    }
}
