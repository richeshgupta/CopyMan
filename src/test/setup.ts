import { vi } from 'vitest';

// Mock Tauri API
const mockWindow = {
  hide: vi.fn().mockResolvedValue(undefined),
  show: vi.fn().mockResolvedValue(undefined),
  setFocus: vi.fn().mockResolvedValue(undefined),
  isVisible: vi.fn().mockResolvedValue(false),
  emit: vi.fn().mockResolvedValue(undefined),
  listen: vi.fn().mockImplementation(() => Promise.resolve(() => {})),
  requestUserAttention: vi.fn().mockResolvedValue(undefined),
};

const mockInvoke = vi.fn().mockImplementation((command: string, args?: any) => {
  switch (command) {
    case 'hide_window':
      return Promise.resolve();
    case 'get_settings':
      return Promise.resolve({
        hotkeys: {
          show_hide: 'Ctrl+Shift+V',
          clear_history: 'Ctrl+Shift+X',
        },
      });
    case 'save_settings':
      return Promise.resolve();
    default:
      return Promise.resolve();
  }
});

const mockListen = vi.fn().mockImplementation((event: string, handler: Function) => {
  return Promise.resolve(() => {});
});

vi.mock('@tauri-apps/api/core', () => ({
  invoke: mockInvoke,
}));

vi.mock('@tauri-apps/api/event', () => ({
  listen: mockListen,
  emit: vi.fn().mockResolvedValue(undefined),
}));

vi.mock('@tauri-apps/api/webviewWindow', () => ({
  getCurrentWebviewWindow: vi.fn(() => mockWindow),
}));

// Export mocks for tests to access
export { mockWindow, mockInvoke, mockListen };
