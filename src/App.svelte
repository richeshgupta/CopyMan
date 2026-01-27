<script lang="ts">
  import SearchBox from "./lib/components/SearchBox.svelte";
  import ClipboardList from "./lib/components/ClipboardList.svelte";
  import Settings from "./lib/components/Settings.svelte";
  import {
    loadHistory,
    clearAllHistory,
    startClipboardListener,
  } from "./lib/stores/clipboard";
  import { theme } from "./lib/stores/theme";
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
    let unlistenIntentionalHide: (() => void) | undefined;
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

      // Listen for intentional hide (from hotkey or menu)
      unlistenIntentionalHide = await listen('intentional-hide', () => {
        console.log('🚫 INTENTIONAL-HIDE EVENT - Setting isHiding flag to TRUE');
        isHiding = true;
        // Reset after window is hidden
        setTimeout(() => {
          console.log('🔄 INTENTIONAL-HIDE: Resetting isHiding to false after 200ms');
          isHiding = false;
        }, 200);
      });

      // Listen for window focus event to focus search input
      unlistenFocus = await listen('window-focused', () => {
        console.log('🎯 WINDOW-FOCUSED EVENT - Resetting isHiding and focusing search input');

        // Reset state when window is shown
        isHiding = false;
        console.log('✅ isHiding reset to false');

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
        console.log('🔵 BLUR EVENT RECEIVED - isDialogOpen:', isDialogOpen, 'isHiding:', isHiding);

        // Don't hide if a dialog is open
        if (isDialogOpen) {
          console.log('⚠️  Dialog is open, not hiding window');
          return;
        }

        // Don't hide if already hiding (prevent race condition)
        if (isHiding) {
          console.log('⚠️  Already hiding, skipping');
          return;
        }

        try {
          isHiding = true;
          console.log('🔻 BLUR HANDLER: Hiding window and resetting settings');
          // Always reset settings state and hide
          showSettings = false;
          await invoke('hide_window');
          console.log('✅ BLUR HANDLER: Window hidden successfully');
        } catch (error) {
          console.error('❌ Error hiding window:', error);
        } finally {
          // Reset flag after a short delay
          setTimeout(() => {
            console.log('🔄 BLUR HANDLER: Resetting isHiding flag');
            isHiding = false;
          }, 100);
        }
      });
    })();

    return () => {
      unlistenClipboard?.();
      unlistenClear?.();
      unlistenSettings?.();
      unlistenIntentionalHide?.();
      unlistenFocus?.();
      unlistenBlur?.then(fn => fn());
    };
  });
</script>

<svelte:window on:keydown={handleGlobalKeydown} />

<main class="app">
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
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", sans-serif;
    background: transparent;
    -webkit-font-smoothing: antialiased;
  }

  .app {
    height: 100vh;
    display: flex;
    flex-direction: column;
    background: white;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
  }

  /* Dark mode */
  :global(.dark) .app {
    background: #1c1c1e;
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.5);
  }
</style>
