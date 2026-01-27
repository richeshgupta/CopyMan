<script lang="ts">
  import { searchQuery, searchClipboard } from '../stores/clipboard';
  import { onMount } from 'svelte';

  let inputValue = '';
  let debounceTimer: ReturnType<typeof setTimeout>;
  let inputElement: HTMLInputElement;

  // Export function to focus input from parent
  export function focusInput() {
    if (inputElement) {
      inputElement.focus();
    }
  }

  function handleInput() {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => {
      searchQuery.set(inputValue);
      searchClipboard(inputValue);
    }, 300);
  }

  function handleKeydown(event: KeyboardEvent) {
    // Only handle Escape to clear search
    // All shortcuts are now handled by ClipboardList's CAPTURE phase listener
    if (event.key === 'Escape') {
      inputValue = '';
      searchQuery.set('');
      searchClipboard('');
      // Refocus after clearing
      if (inputElement) {
        inputElement.focus();
      }
    }

    // All other keys (including shortcuts) are handled by capture phase
    // Normal typing works as expected
  }

  onMount(() => {
    // Focus on mount
    if (inputElement) {
      inputElement.focus();
    }
    return () => clearTimeout(debounceTimer);
  });
</script>

<div class="search-container">
  <input
    type="text"
    bind:this={inputElement}
    bind:value={inputValue}
    on:input={handleInput}
    on:keydown={handleKeydown}
    placeholder="Search clipboard history..."
    class="search-input"
  />
</div>

<style>
  .search-container {
    padding: 12px;
    background: transparent;
  }

  .search-input {
    width: 100%;
    padding: 10px 14px;
    font-size: 15px;
    border: 1px solid #d2d2d7;
    border-radius: 8px;
    background: white;
    color: #1d1d1f;
    outline: none;
    transition: all 0.15s ease;
  }

  .search-input::placeholder {
    color: #86868b;
  }

  .search-input:focus {
    border-color: #007aff;
    box-shadow: 0 0 0 3px rgba(0, 122, 255, 0.1);
  }

  /* Dark mode */
  :global(.dark) .search-input {
    background: #2c2c2e;
    border-color: #38383a;
    color: #f5f5f7;
  }

  :global(.dark) .search-input::placeholder {
    color: #98989d;
  }

  :global(.dark) .search-input:focus {
    border-color: #0a84ff;
    box-shadow: 0 0 0 3px rgba(10, 132, 255, 0.15);
  }
</style>
