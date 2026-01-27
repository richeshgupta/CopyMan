import { writable, derived } from 'svelte/store';
import { invoke } from '@tauri-apps/api/core';
import { listen } from '@tauri-apps/api/event';

export interface ClipboardEntry {
  id: number | null;  // Changed to match Rust Option<i64>
  content: string;
  content_type: string;
  timestamp: number;
  preview: string;
  is_pinned: boolean;
  pin_order: number | null;
}

export const searchQuery = writable<string>('');
export const clipboardHistory = writable<ClipboardEntry[]>([]);
export const isLoading = writable<boolean>(false);

export async function loadHistory(limit: number = 100) {
  isLoading.set(true);
  try {
    const history = await invoke<ClipboardEntry[]>('get_clipboard_history', { limit });
    clipboardHistory.set(history);
  } catch (error) {
    console.error('Failed to load history:', error);
  } finally {
    isLoading.set(false);
  }
}

export async function searchClipboard(query: string) {
  if (!query.trim()) {
    await loadHistory();
    return;
  }

  isLoading.set(true);
  try {
    const results = await invoke<ClipboardEntry[]>('search_clipboard', { query });
    clipboardHistory.set(results);
  } catch (error) {
    console.error('Failed to search:', error);
  } finally {
    isLoading.set(false);
  }
}

export async function copyToClipboard(entryId: number | null) {
  if (entryId === null) {
    console.error('Cannot copy: entry ID is null');
    return;
  }

  try {
    await invoke('copy_to_clipboard', { entryId });
  } catch (error) {
    console.error('Failed to copy:', error);
  }
}

export async function clearAllHistory() {
  try {
    await invoke('clear_all_history');
    clipboardHistory.set([]);
  } catch (error) {
    console.error('Failed to clear history:', error);
  }
}

export async function startClipboardListener(): Promise<() => void> {
  const unlisten = await listen<ClipboardEntry>('clipboard-updated', (event) => {
    console.log('Received clipboard-updated event:', event.payload);
    clipboardHistory.update(history => [event.payload, ...history]);
  });
  return unlisten;
}

export async function pinEntry(id: number | null): Promise<void> {
  if (id === null) {
    console.error('Cannot pin entry: ID is null');
    return;
  }

  try {
    await invoke('pin_clipboard_entry', { id });
    await loadHistory();
  } catch (error) {
    console.error('Failed to pin entry:', error);
  }
}

export async function unpinEntry(id: number | null): Promise<void> {
  if (id === null) {
    console.error('Cannot unpin entry: ID is null');
    return;
  }

  try {
    await invoke('unpin_clipboard_entry', { id });
    await loadHistory();
  } catch (error) {
    console.error('Failed to unpin entry:', error);
  }
}

export async function deleteEntry(id: number | null): Promise<void> {
  if (id === null) {
    console.error('Cannot delete entry: ID is null');
    return;
  }

  console.log('Deleting entry with ID:', id);
  try {
    await invoke('delete_clipboard_entry', { id });
    console.log('Delete successful, reloading history...');
    await loadHistory();
  } catch (error) {
    console.error('Failed to delete entry:', error);
    alert('Failed to delete entry: ' + error);
  }
}
