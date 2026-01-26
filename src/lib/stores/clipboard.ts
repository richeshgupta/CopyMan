import { writable, derived } from 'svelte/store';
import { invoke } from '@tauri-apps/api/core';
import { listen } from '@tauri-apps/api/event';

export interface ClipboardEntry {
  id: number;
  content: string;
  content_type: string;
  timestamp: number;
  preview: string;
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

export async function copyToClipboard(entryId: number) {
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
