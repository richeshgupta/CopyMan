<script lang="ts">
  import { clipboardHistory, isLoading, copyToClipboard, type ClipboardEntry } from '../stores/clipboard';
  import { createVirtualizer } from '@tanstack/svelte-virtual';
  import { onMount } from 'svelte';

  let parentElement: HTMLDivElement;
  let selectedIndex = 0;

  $: virtualizer = createVirtualizer({
    get count() {
      return $clipboardHistory.length;
    },
    getScrollElement: () => parentElement,
    estimateSize: () => 80,
    overscan: 5,
  });

  $: items = $virtualizer.getVirtualItems();
  $: totalSize = $virtualizer.getTotalSize();

  function handleClick(entry: ClipboardEntry) {
    if (entry.id) {
      copyToClipboard(entry.id);
    }
  }

  function handleKeydown(event: KeyboardEvent) {
    const entries = $clipboardHistory;

    if (event.key === 'ArrowDown' || event.key === 'j') {
      event.preventDefault();
      selectedIndex = Math.min(selectedIndex + 1, entries.length - 1);
      scrollToIndex(selectedIndex);
    } else if (event.key === 'ArrowUp' || event.key === 'k') {
      event.preventDefault();
      selectedIndex = Math.max(selectedIndex - 1, 0);
      scrollToIndex(selectedIndex);
    } else if (event.key === 'Enter') {
      event.preventDefault();
      if (entries[selectedIndex]?.id) {
        copyToClipboard(entries[selectedIndex].id!);
      }
    }
  }

  function scrollToIndex(index: number) {
    $virtualizer.scrollToIndex(index, { align: 'center' });
  }

  function formatTimestamp(timestamp: number): string {
    const date = new Date(timestamp * 1000);
    return date.toLocaleString();
  }
</script>

<svelte:window on:keydown={handleKeydown} />

<div class="clipboard-list" bind:this={parentElement}>
  {#if $isLoading}
    <div class="loading">Loading...</div>
  {:else if $clipboardHistory.length === 0}
    <div class="empty">No clipboard history found</div>
  {:else}
    <div style="height: {totalSize}px; position: relative;">
      {#each items as item (item.key)}
        {@const entry = $clipboardHistory[item.index]}
        <button
          class="list-item"
          class:selected={item.index === selectedIndex}
          on:click={() => handleClick(entry)}
          style="position: absolute; top: 0; left: 0; width: 100%; transform: translateY({item.start}px);"
        >
          <div class="preview">{entry.preview}</div>
          <div class="timestamp">{formatTimestamp(entry.timestamp)}</div>
        </button>
      {/each}
    </div>
  {/if}
</div>

<style>
  .clipboard-list {
    flex: 1;
    overflow-y: auto;
    padding: 0 1rem 1rem 1rem;
  }

  .loading, .empty {
    text-align: center;
    padding: 2rem;
    color: #666;
  }

  .list {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .list-item {
    width: 100%;
    padding: 0.75rem 1rem;
    text-align: left;
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 0.5rem;
    cursor: pointer;
    transition: all 0.2s;
  }

  .list-item:hover, .list-item.selected {
    background: #f3f4f6;
    border-color: #3b82f6;
  }

  .preview {
    font-size: 0.875rem;
    color: #111827;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .timestamp {
    font-size: 0.75rem;
    color: #6b7280;
    margin-top: 0.25rem;
  }
</style>
