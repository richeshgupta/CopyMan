<script lang="ts">
  import SearchBox from './lib/components/SearchBox.svelte';
  import ClipboardList from './lib/components/ClipboardList.svelte';
  import { loadHistory } from './lib/stores/clipboard';
  import { onMount } from 'svelte';

  onMount(() => {
    loadHistory();
  });
</script>

<main class="app">
  <header class="header">
    <h1 class="title">CopyMan</h1>
  </header>

  <SearchBox />
  <ClipboardList />
</main>

<style>
  :global(body) {
    margin: 0;
    padding: 0;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  }

  .app {
    height: 100vh;
    display: flex;
    flex-direction: column;
    background: #f9fafb;
  }

  .header {
    padding: 1rem;
    background: white;
    border-bottom: 1px solid #e5e7eb;
  }

  .title {
    margin: 0;
    font-size: 1.5rem;
    font-weight: 600;
    color: #111827;
  }
</style>
