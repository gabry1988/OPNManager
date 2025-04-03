<script lang="ts">
  import { mdiThermometer, mdiChip } from '@mdi/js';
  import { onMount } from 'svelte';
  
  export let temperatureData: { 
    sensors: { 
      device: string;
      device_seq: string;
      temperature: string;
      sensor_type: string;
      type_translated: string;
    }[] 
  };

  // Convert Celsius to Fahrenheit
  function toFahrenheit(celsius: number): number {
    return Math.round((celsius * 9/5) + 32);
  }

  // Determine temperature color based on temperature value
  function getTemperatureColor(temp: number): string {
    if (temp >= 80) return "#ef4444"; // Red - hot/danger
    if (temp >= 70) return "#f97316"; // Orange - warning
    if (temp >= 60) return "#facc15"; // Yellow - caution
    return "#22c55e"; // Green - normal
  }
  
  // Group sensors by type
  $: cpuSensors = temperatureData?.sensors?.filter(s => s.sensor_type === 'cpu') || [];
  $: zoneSensors = temperatureData?.sensors?.filter(s => s.sensor_type === 'zone') || [];
  $: otherSensors = temperatureData?.sensors?.filter(s => s.sensor_type !== 'cpu' && s.sensor_type !== 'zone') || [];
</script>

<div class="card bg-base-100 shadow-xl">
  <div class="card-body">
    <h3 class="card-title text-lg flex items-center gap-2">
      <svg class="w-5 h-5 text-orange-500" viewBox="0 0 24 24">
        <path fill="currentColor" d={mdiThermometer} />
      </svg>
      Temperature Data
    </h3>
    <div class="divider my-2"></div>
    
    {#if temperatureData?.sensors && temperatureData.sensors.length > 0}
      <div class="space-y-4">
        <!-- CPU Temperatures -->
        {#if cpuSensors.length > 0}
          <div>
            <h4 class="text-sm font-medium flex items-center gap-1 mb-2">
              <svg class="w-4 h-4 text-blue-500" viewBox="0 0 24 24">
                <path fill="currentColor" d={mdiChip} />
              </svg>
              {cpuSensors[0]?.type_translated || "CPU"} Cores
            </h4>
            <div class="grid grid-cols-2 gap-x-3 gap-y-3">
              {#each cpuSensors as sensor}
                {@const tempValue = parseFloat(sensor.temperature)}
                {@const tempColor = getTemperatureColor(tempValue)}
                <div>
                  <div class="flex justify-between items-center mb-1">
                    <div class="text-xs font-medium">{sensor.type_translated} {sensor.device_seq}</div>
                    <div class="text-xs font-mono font-semibold" style="color: {tempColor}">
                      {tempValue}°C
                    </div>
                  </div>
                  <div class="h-2 w-full bg-gray-200 rounded-full overflow-hidden">
                    <div 
                      class="h-full transition-all duration-300 ease-in-out" 
                      style="width: {Math.min(tempValue, 100)}%; background-color: {tempColor};"
                    ></div>
                  </div>
                </div>
              {/each}
            </div>
          </div>
        {/if}
        
        <!-- Zone Temperatures -->
        {#if zoneSensors.length > 0}
          <div>
            <h4 class="text-sm font-medium flex items-center gap-1 mb-2">
              <svg class="w-4 h-4 text-purple-500" viewBox="0 0 24 24">
                <path fill="currentColor" d={mdiThermometer} />
              </svg>
              {zoneSensors[0]?.type_translated || "Thermal"} Zones
            </h4>
            <div class="grid grid-cols-2 gap-x-3 gap-y-3">
              {#each zoneSensors as sensor}
                {@const tempValue = parseFloat(sensor.temperature)}
                {@const tempColor = getTemperatureColor(tempValue)}
                <div>
                  <div class="flex justify-between items-center mb-1">
                    <div class="text-xs font-medium">{sensor.type_translated} {sensor.device_seq}</div>
                    <div class="text-xs font-mono font-semibold" style="color: {tempColor}">
                      {tempValue}°C
                    </div>
                  </div>
                  <div class="h-2 w-full bg-gray-200 rounded-full overflow-hidden">
                    <div 
                      class="h-full transition-all duration-300 ease-in-out" 
                      style="width: {Math.min(tempValue, 100)}%; background-color: {tempColor};"
                    ></div>
                  </div>
                </div>
              {/each}
            </div>
          </div>
        {/if}
        
        <!-- Other Sensors -->
        {#if otherSensors.length > 0}
          <div>
            <div class="grid grid-cols-2 gap-x-3 gap-y-3">
              {#each otherSensors as sensor}
                {@const tempValue = parseFloat(sensor.temperature)}
                {@const tempColor = getTemperatureColor(tempValue)}
                <div>
                  <div class="flex justify-between items-center mb-1">
                    <div class="text-xs font-medium">{sensor.type_translated} {sensor.device_seq}</div>
                    <div class="text-xs font-mono font-semibold" style="color: {tempColor}">
                      {tempValue}°C
                    </div>
                  </div>
                  <div class="h-2 w-full bg-gray-200 rounded-full overflow-hidden">
                    <div 
                      class="h-full transition-all duration-300 ease-in-out" 
                      style="width: {Math.min(tempValue, 100)}%; background-color: {tempColor};"
                    ></div>
                  </div>
                </div>
              {/each}
            </div>
          </div>
        {/if}
      </div>
    {:else}
      <p class="text-sm text-center my-4 opacity-70">No temperature sensors detected</p>
    {/if}
  </div>
</div>