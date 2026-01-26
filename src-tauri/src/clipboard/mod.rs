pub mod monitor;

#[cfg(test)]
mod tests {
    use super::monitor::ClipboardMonitor;

    #[test]
    fn test_clipboard_change_detection() {
        let monitor = ClipboardMonitor::new();

        let content1 = "test content 1".to_string();
        let content2 = "test content 2".to_string();

        assert!(monitor.has_changed(&content1, &None));
        assert!(!monitor.has_changed(&content1, &Some(content1.clone())));
        assert!(monitor.has_changed(&content2, &Some(content1)));
    }

    #[test]
    fn test_generate_preview() {
        let monitor = ClipboardMonitor::new();

        let short = "Hello";
        let preview = monitor.generate_preview(short);
        assert_eq!(preview, "Hello");

        let long = "a".repeat(200);
        let preview = monitor.generate_preview(&long);
        assert!(preview.len() <= 103); // 100 chars + "..."
    }
}
