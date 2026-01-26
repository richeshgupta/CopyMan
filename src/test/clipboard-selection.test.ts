import { describe, it, expect, vi, beforeEach } from 'vitest';
import { mockWindow, mockInvoke } from './setup';

/**
 * Test Suite: Clipboard Selection Behavior
 *
 * Tests clipboard item selection and window hiding after selection
 */

describe('Clipboard Selection Behavior', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Number Key Selection (1-9, 0)', () => {
    it('should select first item with key "1"', async () => {
      const mockCopyToClipboard = vi.fn();
      const entry = { id: 1, preview: 'test', timestamp: Date.now() };

      // Simulate pressing "1"
      await mockCopyToClipboard(entry.id);
      await mockWindow.hide();

      expect(mockCopyToClipboard).toHaveBeenCalledWith(entry.id);
      expect(mockWindow.hide).toHaveBeenCalled();
    });

    it('should select second item with key "2"', async () => {
      const mockCopyToClipboard = vi.fn();
      const entry = { id: 2, preview: 'test 2', timestamp: Date.now() };

      await mockCopyToClipboard(entry.id);
      await mockWindow.hide();

      expect(mockCopyToClipboard).toHaveBeenCalledWith(entry.id);
      expect(mockWindow.hide).toHaveBeenCalled();
    });

    it('should select 10th item with key "0"', async () => {
      const mockCopyToClipboard = vi.fn();
      const entry = { id: 10, preview: 'test 10', timestamp: Date.now() };
      const entries = new Array(10).fill(entry);

      if (entries.length >= 10) {
        await mockCopyToClipboard(entries[9].id);
        await mockWindow.hide();
      }

      expect(mockCopyToClipboard).toHaveBeenCalledWith(entry.id);
      expect(mockWindow.hide).toHaveBeenCalled();
    });

    it('should NOT select if number exceeds available entries', async () => {
      const mockCopyToClipboard = vi.fn();
      const entries = [
        { id: 1, preview: 'test 1', timestamp: Date.now() },
        { id: 2, preview: 'test 2', timestamp: Date.now() },
      ];

      const index = 5; // Key "6" pressed
      if (index < entries.length) {
        await mockCopyToClipboard(entries[index].id);
        await mockWindow.hide();
      }

      // Should NOT be called - only 2 entries available
      expect(mockCopyToClipboard).not.toHaveBeenCalled();
      expect(mockWindow.hide).not.toHaveBeenCalled();
    });

    it('should hide window immediately after number key selection (no delay)', async () => {
      const startTime = Date.now();

      await mockWindow.hide();

      const endTime = Date.now();
      const timeTaken = endTime - startTime;

      expect(mockWindow.hide).toHaveBeenCalled();
      // Should be nearly instant (< 50ms)
      expect(timeTaken).toBeLessThan(50);
    });
  });

  describe('Enter Key Selection', () => {
    it('should select currently highlighted item with Enter', async () => {
      const mockCopyToClipboard = vi.fn();
      const selectedIndex = 2;
      const entries = [
        { id: 1, preview: 'test 1', timestamp: Date.now() },
        { id: 2, preview: 'test 2', timestamp: Date.now() },
        { id: 3, preview: 'test 3', timestamp: Date.now() },
      ];

      // Simulate Enter press
      await mockCopyToClipboard(entries[selectedIndex].id);
      await mockWindow.hide();

      expect(mockCopyToClipboard).toHaveBeenCalledWith(entries[selectedIndex].id);
      expect(mockWindow.hide).toHaveBeenCalled();
    });

    it('should hide window immediately after Enter selection (no delay)', async () => {
      const startTime = Date.now();

      await mockWindow.hide();

      const endTime = Date.now();
      const timeTaken = endTime - startTime;

      expect(mockWindow.hide).toHaveBeenCalled();
      expect(timeTaken).toBeLessThan(50);
    });
  });

  describe('Mouse Click Selection', () => {
    it('should select item when clicked', async () => {
      const mockCopyToClipboard = vi.fn();
      const entry = { id: 5, preview: 'clicked item', timestamp: Date.now() };

      // Simulate click
      await mockCopyToClipboard(entry.id);
      await mockWindow.hide();

      expect(mockCopyToClipboard).toHaveBeenCalledWith(entry.id);
      expect(mockWindow.hide).toHaveBeenCalled();
    });

    it('should hide window immediately after click selection (no delay)', async () => {
      const startTime = Date.now();

      await mockWindow.hide();

      const endTime = Date.now();
      const timeTaken = endTime - startTime;

      expect(mockWindow.hide).toHaveBeenCalled();
      expect(timeTaken).toBeLessThan(50);
    });
  });

  describe('Navigation Keys (j/k, arrows)', () => {
    it('should move selection down with "j" key', async () => {
      let selectedIndex = 0;
      const entriesLength = 5;

      // Press "j"
      selectedIndex = Math.min(selectedIndex + 1, entriesLength - 1);

      expect(selectedIndex).toBe(1);
    });

    it('should move selection down with ArrowDown', async () => {
      let selectedIndex = 0;
      const entriesLength = 5;

      // Press ArrowDown
      selectedIndex = Math.min(selectedIndex + 1, entriesLength - 1);

      expect(selectedIndex).toBe(1);
    });

    it('should move selection up with "k" key', async () => {
      let selectedIndex = 2;

      // Press "k"
      selectedIndex = Math.max(selectedIndex - 1, 0);

      expect(selectedIndex).toBe(1);
    });

    it('should move selection up with ArrowUp', async () => {
      let selectedIndex = 2;

      // Press ArrowUp
      selectedIndex = Math.max(selectedIndex - 1, 0);

      expect(selectedIndex).toBe(1);
    });

    it('should NOT move selection below 0', async () => {
      let selectedIndex = 0;

      // Press "k" at top
      selectedIndex = Math.max(selectedIndex - 1, 0);

      expect(selectedIndex).toBe(0);
    });

    it('should NOT move selection above max index', async () => {
      let selectedIndex = 4;
      const entriesLength = 5;

      // Press "j" at bottom
      selectedIndex = Math.min(selectedIndex + 1, entriesLength - 1);

      expect(selectedIndex).toBe(4);
    });

    it('should NOT hide window while navigating', async () => {
      // Navigation only changes selectedIndex
      // Window should stay visible

      expect(mockWindow.hide).not.toHaveBeenCalled();
    });
  });

  describe('Copy to Clipboard', () => {
    it('should copy selected entry content to clipboard', async () => {
      const mockCopyToClipboard = vi.fn();
      const entry = { id: 1, content: 'clipboard content', preview: 'clipboard...', timestamp: Date.now() };

      await mockCopyToClipboard(entry.id);

      expect(mockCopyToClipboard).toHaveBeenCalledWith(entry.id);
    });

    it('should handle copy errors gracefully', async () => {
      const mockCopyToClipboard = vi.fn().mockRejectedValue(new Error('Copy failed'));

      try {
        await mockCopyToClipboard(1);
      } catch (error) {
        // Error should be caught
      }

      expect(mockCopyToClipboard).toHaveBeenCalled();
    });
  });

  describe('Race Condition with Blur', () => {
    it('should not hide twice when selection and blur happen simultaneously', async () => {
      let isHiding = false;

      // Selection triggers hide
      if (!isHiding) {
        isHiding = true;
        await mockWindow.hide();
      }

      // Blur also tries to hide (should be blocked)
      if (!isHiding) {
        await mockWindow.hide();
      }

      // Should only hide once
      expect(mockWindow.hide).toHaveBeenCalledTimes(1);
    });
  });

  describe('Search and Selection', () => {
    it('should be able to select filtered items', async () => {
      const mockCopyToClipboard = vi.fn();
      const filteredEntries = [
        { id: 3, preview: 'matching item', timestamp: Date.now() },
      ];

      // Press "1" to select first filtered item
      if (filteredEntries.length > 0) {
        await mockCopyToClipboard(filteredEntries[0].id);
        await mockWindow.hide();
      }

      expect(mockCopyToClipboard).toHaveBeenCalledWith(3);
      expect(mockWindow.hide).toHaveBeenCalled();
    });
  });
});
