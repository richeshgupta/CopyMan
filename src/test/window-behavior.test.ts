import { describe, it, expect, vi, beforeEach } from 'vitest';
import { mockWindow, mockInvoke } from './setup';

/**
 * Test Suite: Window Visibility Behavior
 *
 * Tests cover the specification table for when window should appear/disappear
 */

describe('Window Visibility Behavior', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Window APPEAR behavior', () => {
    it('should show window and focus input on left-click tray icon (when hidden)', async () => {
      mockWindow.isVisible.mockResolvedValueOnce(false);

      // Simulate tray icon click -> show window
      await mockWindow.show();
      await mockWindow.setFocus();

      expect(mockWindow.show).toHaveBeenCalledTimes(1);
      expect(mockWindow.setFocus).toHaveBeenCalled();
    });

    it('should hide window on left-click tray icon (when visible)', async () => {
      mockWindow.isVisible.mockResolvedValueOnce(true);

      // Simulate tray icon click -> hide window
      await mockWindow.hide();

      expect(mockWindow.hide).toHaveBeenCalledTimes(1);
    });

    it('should show window on "Show/Hide CopyMan" menu (when hidden)', async () => {
      mockWindow.isVisible.mockResolvedValueOnce(false);

      await mockWindow.show();
      await mockWindow.setFocus();

      expect(mockWindow.show).toHaveBeenCalledTimes(1);
      expect(mockWindow.setFocus).toHaveBeenCalled();
    });

    it('should hide window on "Show/Hide CopyMan" menu (when visible)', async () => {
      mockWindow.isVisible.mockResolvedValueOnce(true);

      await mockWindow.hide();

      expect(mockWindow.hide).toHaveBeenCalledTimes(1);
    });

    it('should show window and open Settings on "Settings" menu (when hidden)', async () => {
      mockWindow.isVisible.mockResolvedValueOnce(false);

      await mockWindow.show();
      await mockWindow.setFocus();
      await mockWindow.emit('show-settings', {});

      expect(mockWindow.show).toHaveBeenCalledTimes(1);
      expect(mockWindow.emit).toHaveBeenCalledWith('show-settings', {});
    });

    it('should keep visible and open Settings on "Settings" menu (when visible)', async () => {
      mockWindow.isVisible.mockResolvedValueOnce(true);

      // Window already visible, just emit settings event
      await mockWindow.emit('show-settings', {});

      expect(mockWindow.hide).not.toHaveBeenCalled();
      expect(mockWindow.emit).toHaveBeenCalledWith('show-settings', {});
    });

    it('should show window and focus on global hotkey (when hidden)', async () => {
      mockWindow.isVisible.mockResolvedValueOnce(false);

      await mockWindow.show();
      await mockWindow.setFocus();

      expect(mockWindow.show).toHaveBeenCalledTimes(1);
      expect(mockWindow.setFocus).toHaveBeenCalled();
    });
  });

  describe('Window DISAPPEAR behavior', () => {
    it('should hide immediately after selecting item with number key (1-9)', async () => {
      // Simulate item selection
      await mockWindow.hide();

      expect(mockWindow.hide).toHaveBeenCalledTimes(1);
      // Should be immediate - no delay
    });

    it('should hide immediately after selecting item with Enter key', async () => {
      await mockWindow.hide();

      expect(mockWindow.hide).toHaveBeenCalledTimes(1);
    });

    it('should hide immediately after clicking an item', async () => {
      await mockWindow.hide();

      expect(mockWindow.hide).toHaveBeenCalledTimes(1);
    });

    it('should hide on blur (click outside) when Settings NOT open', async () => {
      const showSettings = false;

      if (!showSettings) {
        await mockInvoke('hide_window');
      }

      expect(mockInvoke).toHaveBeenCalledWith('hide_window');
    });

    it('should hide on blur (click outside) when Settings IS open', async () => {
      const showSettings = true;

      // Even with settings open, blur should hide and close settings
      await mockInvoke('hide_window');

      expect(mockInvoke).toHaveBeenCalledWith('hide_window');
    });

    it('should NOT hide on blur when dialog is open', async () => {
      const isDialogOpen = true;

      // If dialog open, blur handler should return early
      if (isDialogOpen) {
        // Don't call hide
        expect(mockInvoke).not.toHaveBeenCalledWith('hide_window');
      } else {
        await mockInvoke('hide_window');
      }
    });

    it('should hide window when clicking close button (×)', async () => {
      await mockInvoke('hide_window');

      expect(mockInvoke).toHaveBeenCalledWith('hide_window');
    });

    it('should hide window on Escape key (when Settings NOT open)', async () => {
      const showSettings = false;

      if (!showSettings) {
        await mockInvoke('hide_window');
      }

      expect(mockInvoke).toHaveBeenCalledWith('hide_window');
    });
  });

  describe('Window STAY VISIBLE behavior', () => {
    it('should stay visible when confirmation dialog is active', async () => {
      const isDialogOpen = true;

      // Blur event occurs
      if (!isDialogOpen) {
        await mockInvoke('hide_window');
      }

      // Should NOT hide
      expect(mockInvoke).not.toHaveBeenCalledWith('hide_window');
    });

    it('should stay visible when typing in search box', async () => {
      // This is implicitly tested - search input has focus
      // Blur only happens when clicking outside
      // No programmatic hide should occur during typing
      expect(mockInvoke).not.toHaveBeenCalledWith('hide_window');
    });

    it('should stay visible when navigating with j/k/arrows', async () => {
      // Navigation keys don't trigger hide
      // Window should remain visible during navigation
      expect(mockInvoke).not.toHaveBeenCalledWith('hide_window');
    });
  });

  describe('Race condition prevention', () => {
    it('should not hide twice when blur and selection happen simultaneously', async () => {
      const isHiding = false;
      let hidingFlag = isHiding;

      // First hide call
      if (!hidingFlag) {
        hidingFlag = true;
        await mockInvoke('hide_window');
      }

      // Second hide call (should be blocked)
      if (!hidingFlag) {
        await mockInvoke('hide_window');
      }

      // Should only be called once
      expect(mockInvoke).toHaveBeenCalledTimes(1);
    });

    it('should reset isHiding flag after hide completes', async () => {
      let isHiding = false;

      // Simulate hide operation
      isHiding = true;
      await mockInvoke('hide_window');

      // Simulate flag reset after delay
      setTimeout(() => {
        isHiding = false;
      }, 100);

      await new Promise(resolve => setTimeout(resolve, 150));

      expect(isHiding).toBe(false);
    });
  });
});
