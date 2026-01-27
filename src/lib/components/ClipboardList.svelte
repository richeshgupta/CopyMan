<script lang="ts">
  import {
    clipboardHistory,
    isLoading,
    copyToClipboard,
    pinEntry,
    unpinEntry,
    deleteEntry,
    type ClipboardEntry,
  } from "../stores/clipboard";
  import { createVirtualizer } from "@tanstack/svelte-virtual";
  import { onMount, onDestroy } from "svelte";
  import Tooltip from "./Tooltip.svelte";

  let parentElement: HTMLDivElement;
  let selectedIndex = 0;
  let tooltipVisible = false;
  let tooltipContent = "";
  let tooltipTimeout: number | null = null;

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

  async function handleSelect(entry: ClipboardEntry) {
    if (entry.id) {
      await copyToClipboard(entry.id);
      // Hide window after selection
      const { getCurrentWebviewWindow } = await import(
        "@tauri-apps/api/webviewWindow"
      );
      const { invoke } = await import("@tauri-apps/api/core");
      const window = getCurrentWebviewWindow();

      // Emit intentional hide event first
      await window.emit("intentional-hide", {});

      // Small delay then hide via command which will update backend state
      await new Promise((resolve) => setTimeout(resolve, 10));
      await invoke("hide_window");
    }
  }

  async function pasteItem(entry: ClipboardEntry) {
    try {
      const { invoke } = await import("@tauri-apps/api/core");

      // Backend now handles hiding and delay for proper focus switching
      await invoke("paste_clipboard_text", { text: entry.content });
    } catch (error) {
      console.error("Failed to paste:", error);
      // Fallback: just copy
      await handleSelect(entry);
    }
  }

  function handleClick(entry: ClipboardEntry) {
    handleSelect(entry);
  }

  async function handleKeydown(event: KeyboardEvent) {
    const entries = $clipboardHistory;

    if (event.key === "ArrowDown" || event.key === "j") {
      event.preventDefault();
      selectedIndex = Math.min(selectedIndex + 1, entries.length - 1);
      scrollToIndex(selectedIndex);
    } else if (event.key === "ArrowUp" || event.key === "k") {
      event.preventDefault();
      selectedIndex = Math.max(selectedIndex - 1, 0);
      scrollToIndex(selectedIndex);
    } else if (event.key === "Enter") {
      event.preventDefault();
      if (entries[selectedIndex]) {
        if (event.altKey) {
          // Alt+Enter: paste directly
          pasteItem(entries[selectedIndex]);
        } else {
          // Regular Enter: copy
          handleSelect(entries[selectedIndex]);
        }
      }
    } else if (event.key >= "1" && event.key <= "9") {
      event.preventDefault();
      const index = parseInt(event.key) - 1;
      if (index < entries.length) {
        handleSelect(entries[index]);
      }
    } else if (event.key === "0") {
      event.preventDefault();
      if (entries.length >= 10) {
        handleSelect(entries[9]);
      }
    } else if (event.altKey && event.key === "p") {
      // Pin/unpin with Alt+P
      event.preventDefault();
      if (selectedIndex >= 0 && selectedIndex < entries.length) {
        const item = entries[selectedIndex];
        if (item.id) {
          if (item.is_pinned) {
            await unpinEntry(item.id);
          } else {
            await pinEntry(item.id);
          }
        }
      }
    } else if (event.key === "Delete") {
      // Delete with Delete key (or Alt+Delete)
      event.preventDefault();
      if (selectedIndex >= 0 && selectedIndex < entries.length) {
        const item = entries[selectedIndex];
        if (item.id && confirm("Delete this clipboard item?")) {
          console.log("Delete key pressed for entry:", item.id);
          await deleteEntry(item.id);
        }
      }
    }
  }

  function scrollToIndex(index: number) {
    $virtualizer.scrollToIndex(index, { align: "center" });
  }

  function formatTimestamp(timestamp: number): string {
    const date = new Date(timestamp * 1000);
    return date.toLocaleString();
  }

  function showTooltip(entry: ClipboardEntry, event: MouseEvent) {
    tooltipTimeout = window.setTimeout(() => {
      tooltipContent = entry.content;
      tooltipVisible = true;
    }, 500);
  }

  function hideTooltip() {
    if (tooltipTimeout) {
      clearTimeout(tooltipTimeout);
    }
    tooltipVisible = false;
  }

  // Setup capture phase event listener
  let cleanupCaptureListener: (() => void) | null = null;

  onMount(() => {
    console.log("🎯 ClipboardList: Setting up CAPTURE PHASE keyboard listener");

    // Define capture phase handler
    const captureHandler = async (event: KeyboardEvent) => {
      console.log(
        "🔍 CAPTURE PHASE - Key:",
        event.key,
        "Active element:",
        document.activeElement?.tagName,
      );

      const entries = $clipboardHistory;

      // Check if this is a shortcut key
      const isNumberKey = event.key >= "1" && event.key <= "9";
      const isZeroKey = event.key === "0";
      const isNavKey = ["ArrowDown", "ArrowUp", "j", "k"].includes(event.key);
      const isEnterKey = event.key === "Enter";
      const isDeleteKey = event.key === "Delete";
      const isAltP = event.altKey && event.key === "p";
      const isAltEnter = event.altKey && event.key === "Enter";

      // CRITICAL: Handle the global shortcut in frontend if app is focused
      // Identify Ctrl+Shift+V (Linux/Win) or Cmd+Shift+V (Mac)
      const isToggleKey =
        (event.ctrlKey || event.metaKey) &&
        event.shiftKey &&
        (event.key === "v" || event.key === "V");

      const isShortcut =
        isNumberKey ||
        isZeroKey ||
        isNavKey ||
        isEnterKey ||
        isDeleteKey ||
        isAltP ||
        isAltEnter ||
        isToggleKey;

      if (isShortcut) {
        console.log(
          "🛑 SHORTCUT DETECTED - Preventing and stopping propagation",
        );

        // CRITICAL: Prevent the event from reaching the input element
        event.preventDefault();
        event.stopPropagation();

        if (isToggleKey) {
          console.log("🔄 TOGGLE KEY DETECTED - Hiding window");
          const { invoke } = await import("@tauri-apps/api/core");
          await invoke("hide_window");
        } else {
          // Handle other shortcuts
          await handleKeydown(event);
        }
      } else {
        console.log(
          "✏️  Regular key (not a shortcut), allowing normal processing",
        );
      }
    };

    // Register listener in CAPTURE phase (runs BEFORE input element)
    window.addEventListener("keydown", captureHandler, { capture: true });
    console.log("✅ Capture phase listener registered");

    cleanupCaptureListener = () => {
      console.log("🧹 Cleaning up capture phase listener");
      window.removeEventListener("keydown", captureHandler, { capture: true });
    };
  });

  onDestroy(() => {
    if (cleanupCaptureListener) {
      cleanupCaptureListener();
    }
  });
</script>

<div class="clipboard-list" bind:this={parentElement}>
  {#if $isLoading}
    <div class="loading">Loading...</div>
  {:else if $clipboardHistory.length === 0}
    <div class="empty">No clipboard history found</div>
  {:else}
    <div style="height: {totalSize}px; position: relative;">
      {#each items as item (item.key)}
        {@const entry = $clipboardHistory[item.index]}
        <div
          class="list-item"
          class:selected={item.index === selectedIndex}
          class:pinned={entry.is_pinned}
          role="button"
          tabindex="0"
          on:click={() => handleClick(entry)}
          on:keydown={(e) => {
            if (e.key === "Enter" || e.key === " ") handleClick(entry);
          }}
          on:mouseenter={(e) => showTooltip(entry, e)}
          on:mouseleave={hideTooltip}
          style="position: absolute; top: 0; left: 0; width: 100%; transform: translateY({item.start}px);"
        >
          {#if item.index < 10}
            <span class="number-badge"
              >{item.index === 9 ? "0" : item.index + 1}</span
            >
          {/if}
          {#if entry.is_pinned}
            <span class="pin-indicator">📌</span>
          {/if}
          <div class="preview">{entry.preview}</div>
          <div class="timestamp">{formatTimestamp(entry.timestamp)}</div>
          <button
            class="delete-button"
            on:click|stopPropagation={async () => {
              if (entry.id && confirm("Delete this item?")) {
                console.log("Delete button clicked for entry:", entry.id);
                await deleteEntry(entry.id);
              }
            }}
            aria-label="Delete"
          >
            🗑️
          </button>
        </div>
      {/each}
    </div>
  {/if}
</div>

<Tooltip content={tooltipContent} visible={tooltipVisible} />

<style>
  .clipboard-list {
    flex: 1;
    overflow-y: auto;
    padding: 0;
  }

  /* Scrollbar styling */
  .clipboard-list::-webkit-scrollbar {
    width: 10px;
  }

  .clipboard-list::-webkit-scrollbar-track {
    background: transparent;
  }

  .clipboard-list::-webkit-scrollbar-thumb {
    background: #d2d2d7;
    border-radius: 5px;
  }

  :global(.dark) .clipboard-list::-webkit-scrollbar-thumb {
    background: #38383a;
  }

  .loading,
  .empty {
    text-align: center;
    padding: 2rem;
    color: #86868b;
  }

  :global(.dark) .loading,
  :global(.dark) .empty {
    color: #98989d;
  }

  .list-item {
    position: relative;
    width: 100%;
    padding: 10px 14px 10px 50px;
    text-align: left;
    background: transparent;
    border: none;
    border-bottom: 1px solid #d2d2d7;
    cursor: pointer;
    transition: all 0.15s ease;
    display: flex;
    flex-direction: column;
    gap: 3px;
  }

  .list-item:hover {
    background: rgba(0, 122, 255, 0.05);
  }

  .list-item.selected {
    background: rgba(0, 122, 255, 0.1);
  }

  /* Dark mode */
  :global(.dark) .list-item {
    border-bottom-color: #38383a;
  }

  :global(.dark) .list-item:hover {
    background: rgba(10, 132, 255, 0.08);
  }

  :global(.dark) .list-item.selected {
    background: rgba(10, 132, 255, 0.15);
  }

  .preview {
    font-size: 14px;
    color: #1d1d1f;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    line-height: 1.4;
  }

  :global(.dark) .preview {
    color: #f5f5f7;
  }

  .timestamp {
    font-size: 12px;
    color: #86868b;
  }

  :global(.dark) .timestamp {
    color: #98989d;
  }

  .number-badge {
    position: absolute;
    left: 14px;
    top: 50%;
    transform: translateY(-50%);
    min-width: 20px;
    height: 20px;
    padding: 0 6px;
    background: #007aff;
    color: white;
    border-radius: 4px;
    font-size: 11px;
    font-weight: 600;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  :global(.dark) .number-badge {
    background: #0a84ff;
  }

  .list-item.pinned {
    background: rgba(0, 122, 255, 0.03);
  }

  :global(.dark) .list-item.pinned {
    background: rgba(10, 132, 255, 0.05);
  }

  .pin-indicator {
    position: absolute;
    left: 42px;
    top: 50%;
    transform: translateY(-50%);
    font-size: 12px;
    opacity: 0.7;
  }

  .delete-button {
    position: absolute;
    right: 14px;
    top: 50%;
    transform: translateY(-50%);
    background: none;
    border: none;
    font-size: 14px;
    opacity: 0;
    cursor: pointer;
    padding: 4px 8px;
    border-radius: 4px;
    transition:
      opacity 0.15s ease,
      background 0.15s ease;
  }

  .list-item:hover .delete-button {
    opacity: 0.6;
  }

  .delete-button:hover {
    opacity: 1 !important;
    background: rgba(255, 59, 48, 0.1);
  }
</style>
