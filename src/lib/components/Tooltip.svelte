<script lang="ts">
  export let content: string;
  export let visible: boolean = false;

  let tooltipElement: HTMLDivElement;
</script>

{#if visible}
  <div class="tooltip" bind:this={tooltipElement}>
    <div class="tooltip-content">
      {content}
    </div>
  </div>
{/if}

<style>
  .tooltip {
    position: fixed;
    z-index: 9999;
    pointer-events: none;
    animation: fadeIn 150ms ease-in;
  }

  .tooltip-content {
    background: #1d1d1f;
    color: white;
    padding: 8px 12px;
    border-radius: 6px;
    font-size: 13px;
    max-width: 400px;
    max-height: 300px;
    overflow-y: auto;
    white-space: pre-wrap;
    word-break: break-word;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  }

  :global(.dark) .tooltip-content {
    background: #f5f5f7;
    color: #1d1d1f;
  }

  @keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }
</style>
