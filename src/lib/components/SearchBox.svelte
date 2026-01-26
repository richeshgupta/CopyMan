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
    if (event.key === 'Escape') {
      inputValue = '';
      searchQuery.set('');
      searchClipboard('');
      // Refocus after clearing
      if (inputElement) {
        inputElement.focus();
      }
    }
  }

  onMount(() => {
    // Focus on mount
    if (inputElement) {
      inputElement.focus();
    }
    return () => clearTimeout(debounceTimer);
  });
</script>

<div class="search-box">
  <input
    type="text"
    bind:this={inputElement}
    bind:value={inputValue}
    on:input={handleInput}
    on:keydown={handleKeydown}
    placeholder="Search clipboard history..."
    class="w-full px-4 py-3 text-lg border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
  />
</div>

<style>
  .search-box {
    padding: 1rem;
  }
</style>
