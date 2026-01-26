<script lang="ts">
  import { searchQuery, searchClipboard } from '../stores/clipboard';
  import { onMount } from 'svelte';

  let inputValue = '';
  let debounceTimer: ReturnType<typeof setTimeout>;

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
    }
  }

  onMount(() => {
    return () => clearTimeout(debounceTimer);
  });
</script>

<div class="search-box">
  <input
    type="text"
    bind:value={inputValue}
    on:input={handleInput}
    on:keydown={handleKeydown}
    placeholder="Search clipboard history..."
    class="w-full px-4 py-3 text-lg border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
    autofocus
  />
</div>

<style>
  .search-box {
    padding: 1rem;
  }
</style>
