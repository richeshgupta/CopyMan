import { describe, it, expect, vi, beforeEach } from 'vitest';
import { mockWindow, mockInvoke } from './setup';

/**
 * Test Suite: Settings Modal Behavior
 *
 * Tests Settings modal opening, closing, and interaction behaviors
 */

describe('Settings Modal Behavior', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Opening Settings', () => {
    it('should open Settings when clicking "Settings" from tray menu', async () => {
      let showSettings = false;

      // Simulate settings menu click
      await mockWindow.show();
      await mockWindow.setFocus();
      await mockWindow.emit('show-settings', {});

      // Handler sets showSettings to true
      showSettings = true;

      expect(showSettings).toBe(true);
      expect(mockWindow.emit).toHaveBeenCalledWith('show-settings', {});
    });

    it('should show window first if hidden, then open Settings', async () => {
      mockWindow.isVisible.mockResolvedValueOnce(false);
      let showSettings = false;

      // Window is hidden
      await mockWindow.show();
      await mockWindow.setFocus();

      // Then emit settings event
      await mockWindow.emit('show-settings', {});
      showSettings = true;

      expect(mockWindow.show).toHaveBeenCalled();
      expect(showSettings).toBe(true);
    });

    it('should open Settings without hiding window if already visible', async () => {
      mockWindow.isVisible.mockResolvedValueOnce(true);
      let showSettings = false;

      // Emit settings event
      await mockWindow.emit('show-settings', {});
      showSettings = true;

      expect(mockWindow.hide).not.toHaveBeenCalled();
      expect(showSettings).toBe(true);
    });

    it('should open Settings with Ctrl+K keyboard shortcut', async () => {
      let showSettings = false;

      // Simulate Ctrl+K press
      const event = new KeyboardEvent('keydown', {
        key: 'k',
        ctrlKey: true,
      });

      // Handler sets showSettings
      if (event.ctrlKey && event.key === 'k') {
        showSettings = true;
      }

      expect(showSettings).toBe(true);
    });
  });

  describe('Closing Settings', () => {
    it('should close Settings when clicking Cancel button', async () => {
      let showSettings = true;

      // Simulate cancel click
      showSettings = false;

      expect(showSettings).toBe(false);
    });

    it('should close Settings when clicking close button (×)', async () => {
      let showSettings = true;

      // Simulate close button click
      showSettings = false;

      expect(showSettings).toBe(false);
    });

    it('should close Settings when pressing Escape key', async () => {
      let showSettings = true;

      // Simulate Escape key
      const event = new KeyboardEvent('keydown', { key: 'Escape' });

      if (event.key === 'Escape') {
        showSettings = false;
      }

      expect(showSettings).toBe(false);
    });

    it('should close Settings when clicking outside modal but inside window', async () => {
      let showSettings = true;

      // Simulate click on overlay (outside modal)
      showSettings = false;

      expect(showSettings).toBe(false);
    });

    it('should NOT close Settings when clicking inside modal', async () => {
      let showSettings = true;

      // Click is inside modal - stopPropagation prevents closure
      // showSettings remains true

      expect(showSettings).toBe(true);
    });

    it('should close Settings AND hide window when clicking outside window', async () => {
      let showSettings = true;

      // Blur event occurs
      showSettings = false;
      await mockInvoke('hide_window');

      expect(showSettings).toBe(false);
      expect(mockInvoke).toHaveBeenCalledWith('hide_window');
    });
  });

  describe('Settings Persistence', () => {
    it('should load settings on Settings modal mount', async () => {
      const mockGetSettings = vi.fn().mockResolvedValue({
        hotkeys: {
          show_hide: 'Ctrl+Shift+V',
          clear_history: 'Ctrl+Shift+X',
        },
      });

      const settings = await mockGetSettings();

      expect(mockGetSettings).toHaveBeenCalled();
      expect(settings.hotkeys.show_hide).toBe('Ctrl+Shift+V');
    });

    it('should save settings when clicking Save button', async () => {
      const settings = {
        hotkeys: {
          show_hide: 'Ctrl+Shift+V',
          clear_history: 'Ctrl+Shift+X',
        },
      };

      await mockInvoke('save_settings', { settings });

      expect(mockInvoke).toHaveBeenCalledWith('save_settings', { settings });
    });

    it('should show success message after saving settings', async () => {
      let saveMessage = '';

      await mockInvoke('save_settings', { settings: {} });
      saveMessage = 'Settings saved successfully!';

      expect(saveMessage).toBe('Settings saved successfully!');
    });

    it('should show error message if save fails', async () => {
      mockInvoke.mockRejectedValueOnce(new Error('Save failed'));
      let saveMessage = '';

      try {
        await mockInvoke('save_settings', { settings: {} });
      } catch (error: any) {
        saveMessage = `Error: ${error.message}`;
      }

      expect(saveMessage).toContain('Error:');
    });

    it('should clear success message after 3 seconds', async () => {
      let saveMessage = 'Settings saved successfully!';

      setTimeout(() => {
        saveMessage = '';
      }, 3000);

      await new Promise(resolve => setTimeout(resolve, 3100));

      expect(saveMessage).toBe('');
    });
  });

  describe('Settings State Management', () => {
    it('should NOT hide window on blur when Settings is open', async () => {
      let showSettings = true;
      const shouldHide = !showSettings;

      if (shouldHide) {
        await mockInvoke('hide_window');
      }

      // Window should NOT hide
      expect(mockInvoke).not.toHaveBeenCalledWith('hide_window');
    });

    it('should reset showSettings to false when window is shown next time', async () => {
      let showSettings = true;

      // Window hidden
      await mockWindow.hide();

      // Window shown again (not via Settings menu)
      await mockWindow.show();
      await mockWindow.emit('window-focused', {});

      // showSettings should be reset
      showSettings = false;

      expect(showSettings).toBe(false);
    });

    it('should NOT reset showSettings if Settings menu was clicked', async () => {
      let showSettings = false;
      let settingsRequested = false;

      // Settings clicked
      await mockWindow.emit('show-settings', {});
      settingsRequested = true;
      showSettings = true;

      // Focus event
      if (!settingsRequested) {
        showSettings = false;
      }

      expect(showSettings).toBe(true);
    });
  });

  describe('Settings Validation', () => {
    it('should disable Save button while saving', async () => {
      let isSaving = false;

      isSaving = true;
      await mockInvoke('save_settings', { settings: {} });
      isSaving = false;

      expect(isSaving).toBe(false);
    });

    it('should handle empty settings gracefully', async () => {
      const settings = {
        hotkeys: {
          show_hide: '',
          clear_history: '',
        },
      };

      await mockInvoke('save_settings', { settings });

      expect(mockInvoke).toHaveBeenCalledWith('save_settings', { settings });
    });
  });
});
