pub mod clipboard;

#[cfg(test)]
mod tests {
    use super::clipboard::*;
    use crate::state::AppState;
    use std::sync::{Arc, Mutex};

    fn create_test_state() -> tauri::State<Arc<Mutex<AppState>>> {
        // This is a mock - actual testing will be manual/integration
        unimplemented!("Use integration tests for Tauri commands")
    }
}
