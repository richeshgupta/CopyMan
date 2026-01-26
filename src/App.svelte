<script lang="ts">
  import SearchBox from "./lib/components/SearchBox.svelte";
  import ClipboardList from "./lib/components/ClipboardList.svelte";
  import Settings from "./lib/components/Settings.svelte";
  import {
    loadHistory,
    clearAllHistory,
    startClipboardListener,
  } from "./lib/stores/clipboard";
  import { listen } from "@tauri-apps/api/event";
  import { getCurrentWebviewWindow } from '@tauri-apps/api/webviewWindow';
  import { invoke } from '@tauri-apps/api/core';
  import { onMount } from "svelte";

  let showSettings = false;
  let searchBoxComponent: any;

  // Test if JavaScript is executing
  console.log('===== APP.SVELTE LOADED =====');
  console.log('Initial showSettings value:', showSettings);

  // Debug: Log when showSettings changes
  $: console.log('showSettings:', showSettings);

  // Test function to manually trigger settings (for debugging)
  function testShowSettings() {
    console.log('Manually triggering settings');
    showSettings = true;
  }

  // Add keyboard shortcut for testing (Ctrl+K)
  function handleGlobalKeydown(event: KeyboardEvent) {
    if (event.ctrlKey && event.key === 'k') {
      event.preventDefault();
      testShowSettings();
    }
  }

  onMount(() => {
    let unlistenClipboard: (() => void) | undefined;
    let unlistenClear: (() => void) | undefined;
    let unlistenSettings: (() => void) | undefined;
    let unlistenFocus: (() => void) | undefined;
    let unlistenBlur: Promise<() => void> | undefined;

    // Track if we're showing a dialog to prevent blur from hiding
    let isDialogOpen = false;
    // Track if we're already hiding to prevent race conditions
    let isHiding = false;

    (async () => {
      console.log('App.svelte onMount - starting initialization');
      await loadHistory();
      unlistenClipboard = await startClipboardListener();

      unlistenClear = await listen("clear-history-request", async () => {
        isDialogOpen = true;
        const shouldClear = confirm("Clear all clipboard history?");
        isDialogOpen = false;

        if (shouldClear) {
          await clearAllHistory();
        }
      });

      // Listen for settings event from tray menu
      console.log('Setting up show-settings listener...');
      unlistenSettings = await listen('show-settings', (event) => {
        console.log('Settings event received - setting showSettings to true', event);
        showSettings = true;
        console.log('showSettings is now:', showSettings);
      });
      console.log('show-settings listener set up successfully');

      // Listen for window focus event to focus search input
      unlistenFocus = await listen('window-focused', () => {
        console.log('Window focused event - focusing search input');

        // Reset state when window is shown
        isHiding = false;

        // Focus the search input using the component's method
        // Don't focus if settings is open
        // Try immediately and then again with delays to ensure it works
        if (searchBoxComponent && !showSettings) {
          searchBoxComponent.focusInput();
        }
        setTimeout(() => {
          if (searchBoxComponent && !showSettings) {
            searchBoxComponent.focusInput();
            console.log('Search input focused via component method');
          }
        }, 50);
        setTimeout(() => {
          if (searchBoxComponent && !showSettings) {
            searchBoxComponent.focusInput();
          }
        }, 150);
      });

      const window = getCurrentWebviewWindow();

      // Add blur listener to hide window when clicking outside
      unlistenBlur = window.listen('tauri://blur', async () => {
        console.log('Blur event received');

        // Don't hide if a dialog is open
        if (isDialogOpen) {
          console.log('Dialog is open, not hiding window');
          return;
        }

        // Don't hide if already hiding (prevent race condition)
        if (isHiding) {
          console.log('Already hiding, skipping');
          return;
        }

        try {
          isHiding = true;
          console.log('Hiding window and resetting settings');
          // Always reset settings state and hide
          showSettings = false;
          await invoke('hide_window');
        } catch (error) {
          console.error('Error hiding window:', error);
        } finally {
          // Reset flag after a short delay
          setTimeout(() => {
            isHiding = false;
          }, 100);
        }
      });
    })();

    return () => {
      unlistenClipboard?.();
      unlistenClear?.();
      unlistenSettings?.();
      unlistenFocus?.();
      unlistenBlur?.then(fn => fn());
    };
  });
</script>

<svelte:window on:keydown={handleGlobalKeydown} />

<main class="app">
  <header class="header">
    <h1 class="title">CopyMan</h1>
    <button class="close-button" on:click={async () => await invoke('hide_window')}>
      ×
    </button>
  </header>

  <SearchBox bind:this={searchBoxComponent} />
  <ClipboardList />

  {#if showSettings}
    <Settings onClose={() => showSettings = false} />
  {/if}
</main>

<style>
  :global(body) {
    margin: 0;
    padding: 0;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
      sans-serif;
    background: transparent;
  }

  .app {
    height: 100vh;
    display: flex;
    flex-direction: column;
    background: #f9fafb;
    border: 1px solid #d1d5db;
    border-radius: 0.5rem;
    overflow: hidden;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
  }

  .header {
    padding: 1rem;
    background: white;
    border-bottom: 1px solid #e5e7eb;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .title {
    margin: 0;
    font-size: 1.5rem;
    font-weight: 600;
    color: #111827;
  }

  .close-button {
    background: none;
    border: none;
    font-size: 1.5rem;
    color: #6b7280;
    cursor: pointer;
    padding: 0;
    width: 2rem;
    height: 2rem;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 0.25rem;
    transition: background-color 0.2s, color 0.2s;
  }

  .close-button:hover {
    background: #f3f4f6;
    color: #111827;
  }
</style>
