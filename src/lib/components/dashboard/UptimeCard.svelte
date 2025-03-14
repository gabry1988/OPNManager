<script lang="ts">
    import { mdiClockOutline } from '@mdi/js';
  
    export let systemTime: {
      uptime: string;
      datetime: string;
      config: string;
      loadavg: string;
    };
</script>
  
<div class="card bg-base-100 shadow-xl">
  <div class="card-body">
    <h3 class="card-title text-lg flex items-center gap-2">
      <svg class="w-5 h-5 text-primary" viewBox="0 0 24 24">
        <path fill="currentColor" d={mdiClockOutline} />
      </svg>
      System Status
    </h3>
    
    <div class="divider my-2"></div>
    
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div class="space-y-3">
        <div>
          <h4 class="text-sm font-medium opacity-70">Uptime</h4>
          <p class="text-lg font-mono">{systemTime.uptime}</p>
        </div>
        
        <div>
          <h4 class="text-sm font-medium opacity-70">Load average</h4>
          <p class="text-lg font-mono">{systemTime.loadavg}</p>
        </div>
      </div>
      
      <div class="space-y-3">
        <div>
          <h4 class="text-sm font-medium opacity-70">Current date/time</h4>
          <p class="text-lg font-mono">{systemTime.datetime}</p>
        </div>
        
        <div>
          <h4 class="text-sm font-medium opacity-70">Last configuration change</h4>
          <p class="text-lg font-mono">{systemTime.config}</p>
        </div>
      </div>
    </div>
  </div>
</div>