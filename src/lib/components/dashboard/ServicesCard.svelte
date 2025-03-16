<script lang="ts">
  import { 
    mdiServerNetwork, 
    mdiChevronUp, 
    mdiChevronDown,
    mdiRestart 
  } from '@mdi/js';

  export let services: any[];
  export let expandedServices: boolean;
  export let toggleServicesExpansion: () => void;
  export let restartService: (serviceId: string) => Promise<void>;
  
  function truncateText(text: string, maxLength: number): string {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  }
</script>

<div class="card bg-base-100 shadow-xl">
<div class="card-body">
  <div class="flex justify-between items-center">
    <h3 class="card-title text-lg flex items-center gap-2">
      <svg class="w-5 h-5 text-secondary" viewBox="0 0 24 24">
        <path fill="currentColor" d={mdiServerNetwork} />
      </svg>
      Services
      <span class="badge badge-sm ml-2">
        {services.length}
      </span>
    </h3>
    <button 
      class="btn btn-ghost btn-sm" 
      on:click={toggleServicesExpansion}
    >
      <svg class="w-5 h-5" viewBox="0 0 24 24">
        <path 
          fill="currentColor" 
          d={expandedServices ? mdiChevronUp : mdiChevronDown} 
        />
      </svg>
    </button>
  </div>

  {#if expandedServices}
    <div class="divider my-2"></div>
    <div class="space-y-3">
      {#each services as service}
        <div 
          class="border rounded-lg p-3 
          {service.running ? 'bg-success/10 border-success/30' : 'bg-error/10 border-error/30'}"
        >
          <div class="grid grid-cols-[1fr,auto] gap-2 items-center">
            <div class="min-w-0 overflow-hidden">
              <div class="font-medium truncate" title={service.name}>
                {truncateText(service.name, 24)}
              </div>
              <div class="text-sm opacity-70 truncate" title={service.description}>
                {truncateText(service.description, 36)}
              </div>
            </div>
            <div class="flex items-center space-x-2 shrink-0">
              <span 
                class="badge whitespace-nowrap {service.running ? 'badge-success' : 'badge-error'}"
              >
                {service.running ? 'Running' : 'Stopped'}
              </span>
              <button 
                class="btn btn-ghost btn-sm shrink-0" 
                on:click={() => restartService(service.id)}
                title="Restart Service"
                aria-label="Restart {service.name} Service"
              >
                <svg class="w-5 h-5" viewBox="0 0 24 24">
                  <path fill="currentColor" d={mdiRestart} />
                </svg>
              </button>
            </div>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>
</div>

<style>
/* Additional truncation styles for better control */
.truncate {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
</style>