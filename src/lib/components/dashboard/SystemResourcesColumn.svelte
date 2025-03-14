<script lang="ts">
  import MemoryUsageCard from './MemoryUsageCard.svelte';
  import DiskUsageCard from './DiskUsageCard.svelte';
  import ServicesCard from './ServicesCard.svelte';
  import UptimeCard from './UptimeCard.svelte';

  export let systemResources: any;
  export let mainDisk: any;
  export let services: any[];
  export let expandedServices: boolean;
  export let toggleServicesExpansion: () => void;
  export let restartService: (serviceId: string) => Promise<void>;
  export let systemTime: any;
</script>

<div class="space-y-6 order-first lg:order-last">
  <!-- Uptime Card -->
  {#if systemTime}
    <UptimeCard {systemTime} />
  {/if}
  
  <!-- Memory Usage Card -->
  {#if systemResources}
    <MemoryUsageCard {systemResources} />
  {/if}

  <!-- Disk Usage Card -->
  {#if mainDisk}
    <DiskUsageCard {mainDisk} />
  {/if}

  <!-- Services Card -->
  <ServicesCard 
    {services}
    {expandedServices}
    {toggleServicesExpansion}
    {restartService}
  />
</div>