<script lang="ts">
  import { onMount } from 'svelte';
  import { invoke } from '@tauri-apps/api/core';

  export let onClose: () => void;

  interface Settings {
    hotkeys: {
      show_hide: string;
      clear_history: string;
    };
  }

  let settings: Settings = {
    hotkeys: {
      show_hide: 'Ctrl+Shift+V',
      clear_history: 'Ctrl+Shift+X',
    },
  };

  let isSaving = false;
  let saveMessage = '';

  onMount(async () => {
    try {
      settings = await invoke<Settings>('get_settings');
    } catch (error) {
      console.error('Failed to load settings:', error);
    }
  });

  async function saveSettings() {
    isSaving = true;
    saveMessage = '';

    try {
      await invoke('save_settings', { settings });
      saveMessage = 'Settings saved successfully!';
      setTimeout(() => {
        saveMessage = '';
      }, 3000);
    } catch (error) {
      saveMessage = `Error: ${error}`;
      console.error('Failed to save settings:', error);
    } finally {
      isSaving = false;
    }
  }

  function handleKeydown(event: KeyboardEvent) {
    if (event.key === 'Escape') {
      onClose();
    }
  }
</script>

<svelte:window on:keydown={handleKeydown} />

<!-- svelte-ignore a11y-click-events-have-key-events -->
<!-- svelte-ignore a11y-no-static-element-interactions -->
<div class="settings-overlay" on:click={onClose}>
  <!-- svelte-ignore a11y-click-events-have-key-events -->
  <!-- svelte-ignore a11y-no-static-element-interactions -->
  <div class="settings-panel" on:click|stopPropagation>
    <div class="settings-header">
      <h2>Settings</h2>
      <button class="close-btn" on:click={onClose}>&times;</button>
    </div>

    <div class="settings-content">
      <section>
        <h3>Hotkeys</h3>

        <div class="setting-item">
          <label for="show-hide-key">Show/Hide Window</label>
          <input
            id="show-hide-key"
            type="text"
            bind:value={settings.hotkeys.show_hide}
            placeholder="e.g., Ctrl+Shift+V"
          />
          <p class="hint">Format: Ctrl+Shift+Key or Alt+Key</p>
        </div>

        <div class="setting-item">
          <label for="clear-key">Clear History</label>
          <input
            id="clear-key"
            type="text"
            bind:value={settings.hotkeys.clear_history}
            placeholder="e.g., Ctrl+Shift+X"
          />
          <p class="hint">Format: Ctrl+Shift+Key or Alt+Key</p>
        </div>
      </section>

      {#if saveMessage}
        <div class="save-message" class:error={saveMessage.startsWith('Error')}>
          {saveMessage}
        </div>
      {/if}

      <div class="actions">
        <button class="btn btn-secondary" on:click={onClose}>Cancel</button>
        <button
          class="btn btn-primary"
          on:click={saveSettings}
          disabled={isSaving}
        >
          {isSaving ? 'Saving...' : 'Save Settings'}
        </button>
      </div>
    </div>
  </div>
</div>

<style>
  .settings-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
  }

  .settings-panel {
    background: white;
    border-radius: 0.5rem;
    width: 90%;
    max-width: 500px;
    max-height: 90vh;
    overflow-y: auto;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
  }

  .settings-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1.5rem;
    border-bottom: 1px solid #e5e7eb;
  }

  .settings-header h2 {
    margin: 0;
    font-size: 1.5rem;
    font-weight: 600;
    color: #111827;
  }

  .close-btn {
    background: none;
    border: none;
    font-size: 2rem;
    color: #6b7280;
    cursor: pointer;
    padding: 0;
    width: 2rem;
    height: 2rem;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: color 0.2s;
  }

  .close-btn:hover {
    color: #111827;
  }

  .settings-content {
    padding: 1.5rem;
  }

  section {
    margin-bottom: 2rem;
  }

  section h3 {
    margin: 0 0 1rem 0;
    font-size: 1.125rem;
    font-weight: 600;
    color: #374151;
  }

  .setting-item {
    margin-bottom: 1.5rem;
  }

  .setting-item label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: 500;
    color: #374151;
  }

  .setting-item input {
    width: 100%;
    padding: 0.5rem 0.75rem;
    border: 1px solid #d1d5db;
    border-radius: 0.375rem;
    font-size: 0.875rem;
    transition: border-color 0.2s;
  }

  .setting-item input:focus {
    outline: none;
    border-color: #3b82f6;
    box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
  }

  .hint {
    margin: 0.25rem 0 0 0;
    font-size: 0.75rem;
    color: #6b7280;
  }

  .save-message {
    padding: 0.75rem;
    margin-bottom: 1rem;
    border-radius: 0.375rem;
    background: #d1fae5;
    color: #065f46;
    font-size: 0.875rem;
  }

  .save-message.error {
    background: #fee2e2;
    color: #991b1b;
  }

  .actions {
    display: flex;
    gap: 0.75rem;
    justify-content: flex-end;
  }

  .btn {
    padding: 0.5rem 1rem;
    border: none;
    border-radius: 0.375rem;
    font-size: 0.875rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }

  .btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .btn-secondary {
    background: white;
    color: #374151;
    border: 1px solid #d1d5db;
  }

  .btn-secondary:hover:not(:disabled) {
    background: #f9fafb;
  }

  .btn-primary {
    background: #3b82f6;
    color: white;
  }

  .btn-primary:hover:not(:disabled) {
    background: #2563eb;
  }
</style>
