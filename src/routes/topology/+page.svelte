<script lang="ts">
  import { onMount } from "svelte";
  import AppLayout from "../AppLayout.svelte";
  import TopologyMap from "$lib/components/topology/TopologyMap.svelte";
  import TopologyDetails from "$lib/components/topology/TopologyDetails.svelte";
  import { invoke } from "@tauri-apps/api/core";
  import { toasts } from "$lib/stores/toastStore";
  import { mdiRefresh, mdiInformation, mdiEye, mdiEyeOff, mdiMenuDown } from "@mdi/js";
  import type { Interface } from "$lib/components/topology/types";
  import type { CombinedDevice } from "$lib/components/topology/types";

  let interfaces: Interface[] = [];
  let devices: CombinedDevice[] = [];
  let isLoading = true;
  let error: string | null = null;
  let selectedElement: Interface | CombinedDevice | null = null;
  let showDetailsPanel = false;
  let selectedInterfaces: string[] = [];
  let isFilterDropdownOpen = false;

  onMount(async () => {
    await fetchData();
  });

  async function fetchData() {
    isLoading = true;
    error = null;
    try {
      // Fetch data in parallel
      const [interfacesData, devicesData] = await Promise.all([
        invoke<Interface[]>("get_interfaces"),
        invoke<CombinedDevice[]>("get_combined_devices")
      ]);
      
      interfaces = interfacesData;
      devices = devicesData;
      
      // Initialize selected interfaces if this is the first load
      if (selectedInterfaces.length === 0) {
        // By default, show all active interfaces
        selectedInterfaces = interfaces
          .filter(iface => iface.status?.toLowerCase() === 'up' && (iface.identifier || iface.is_physical))
          .map(iface => iface.device);
      }
      
      console.log(`Fetched ${interfaces.length} interfaces and ${devices.length} devices`);
    } catch (err) {
      console.error("Failed to fetch network data:", err);
      error = `Failed to fetch network data: ${err}`;
      toasts.error("Failed to load network topology data");
    } finally {
      isLoading = false;
    }
  }

  function handleElementSelect(event) {
    console.log("Element selected event received in +page.svelte:", event);
    
    // Check if detail is directly on the event or inside event.detail
    const detail = event.detail || event;
    
    console.log("Element selected:", detail.type, detail.element);
    
    // DEBUG: Let's verify what we're getting
    if (detail && detail.element) {
      console.log("*** SETTING selectedElement to:", detail.element);
      console.log("*** Element has properties:", Object.keys(detail.element));
      
      // Set both state variables and force re-render
      selectedElement = detail.element;
      showDetailsPanel = true;
      
      console.log("*** AFTER setting: selectedElement=", selectedElement, "showDetailsPanel=", showDetailsPanel);
    } else {
      console.error("Missing element in event detail:", detail);
    }
  }

  function closeDetailsPanel() {
    console.log('Closing details panel');
    showDetailsPanel = false;
    selectedElement = null; // Remove timeout to ensure immediate cleanup
  }
  
  function toggleInterface(ifaceName: string) {
    if (selectedInterfaces.includes(ifaceName)) {
      selectedInterfaces = selectedInterfaces.filter(name => name !== ifaceName);
    } else {
      selectedInterfaces = [...selectedInterfaces, ifaceName];
    }
  }
  
  function toggleAllInterfaces() {
    if (selectedInterfaces.length === getActiveInterfaces().length) {
      // If all are selected, deselect all
      selectedInterfaces = [];
    } else {
      // Otherwise, select all
      selectedInterfaces = getActiveInterfaces().map(iface => iface.device);
    }
  }
  
  function getActiveInterfaces() {
    return interfaces.filter(iface => 
      iface.status?.toLowerCase() === 'up' && (iface.identifier || iface.is_physical)
    );
  }
  
  function toggleFilterDropdown() {
    isFilterDropdownOpen = !isFilterDropdownOpen;
  }
  
  // Filter interfaces based on selection
  $: filteredInterfaces = interfaces.filter(iface => selectedInterfaces.includes(iface.device));
  
  // Count total active interfaces for UI
  $: totalActiveInterfaces = getActiveInterfaces().length;
  
  // Log filter changes
  $: if (filteredInterfaces.length > 0) {
    console.log(`Filter changed: showing ${filteredInterfaces.length} interfaces`);
  }
</script>

<AppLayout>
  <div class="flex flex-col h-full topology-page-container">
    <div class="flex flex-wrap justify-between items-center px-2 py-1 gap-2">
      <h1 class="text-2xl font-bold">Network Topology</h1>
      
      <div class="flex flex-wrap gap-2">
        <!-- Interface selection dropdown -->
        <div class="dropdown dropdown-end">
          <button 
            class="btn btn-sm btn-primary text-white flex items-center gap-1" 
            on:click={toggleFilterDropdown}
          >
            <span>Interfaces</span>
            <svg class="w-5 h-5" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiMenuDown} />
            </svg>
          </button>
          
          {#if isFilterDropdownOpen}
            <div class="dropdown-content z-30 menu p-2 shadow bg-base-100 border border-base-300 rounded-box w-64 mt-1">
              <div class="p-2 border-b border-base-300">
                <label class="cursor-pointer label justify-start gap-2">
                  <input 
                    type="checkbox" 
                    class="checkbox checkbox-sm checkbox-primary" 
                    checked={selectedInterfaces.length === totalActiveInterfaces}
                    on:change={toggleAllInterfaces}
                  />
                  <span class="label-text font-medium">Select All ({totalActiveInterfaces})</span>
                </label>
              </div>
              
              <div class="max-h-[min(60vh,300px)] overflow-y-auto">
                {#each getActiveInterfaces() as iface}
                  <label class="cursor-pointer label justify-start gap-2 hover:bg-base-200 rounded py-2">
                    <input 
                      type="checkbox" 
                      class="checkbox checkbox-sm checkbox-primary" 
                      checked={selectedInterfaces.includes(iface.device)}
                      on:change={() => toggleInterface(iface.device)}
                    />
                    <div class="flex flex-col">
                      <span class="label-text font-medium">{iface.description || iface.device}</span>
                      <span class="label-text text-xs opacity-70">{iface.device}</span>
                    </div>
                    {#if selectedInterfaces.includes(iface.device)}
                      <svg class="w-4 h-4 ml-auto text-success" viewBox="0 0 24 24">
                        <path fill="currentColor" d={mdiEye} />
                      </svg>
                    {:else}
                      <svg class="w-4 h-4 ml-auto text-error" viewBox="0 0 24 24">
                        <path fill="currentColor" d={mdiEyeOff} />
                      </svg>
                    {/if}
                  </label>
                {/each}
              </div>
            </div>
          {/if}
        </div>
        
        <button 
          class="btn btn-sm btn-primary text-white" 
          on:click={fetchData}
          disabled={isLoading}
        >
          <svg class="w-5 h-5 {isLoading ? 'animate-spin' : ''}" viewBox="0 0 24 24">
            <path fill="currentColor" d={mdiRefresh} />
          </svg>
          Refresh
        </button>
      </div>
    </div>
    
    {#if isLoading}
      <div class="flex justify-center items-center py-12">
        <div class="text-center">
          <span class="loading loading-spinner loading-lg"></span>
          <p class="mt-4 text-base-content">Loading network topology...</p>
        </div>
      </div>
    {:else if error}
      <div class="alert alert-error shadow-lg mb-4">
        <div>
          <svg
            class="w-6 h-6"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <div>
            <h3 class="font-bold">Error</h3>
            <div class="text-xs">{error}</div>
          </div>
        </div>
        <div class="flex-none">
          <button class="btn btn-sm" on:click={fetchData}>Retry</button>
        </div>
      </div>
    {:else}
      <!-- Full width layout with modal details -->
      <div class="relative flex-1 h-[calc(100vh-13rem)]">
        <div class="w-full h-full overflow-hidden">
          <TopologyMap
            interfaces={filteredInterfaces}
            devices={devices}
            onElementSelect={(element, type) => {
              console.log('Direct callback from TopologyMap:', type, element);
              selectedElement = element;
              showDetailsPanel = true;
            }}
            on:elementSelect={handleElementSelect}
          />
        </div>
        
        {#if showDetailsPanel && selectedElement}
          <div class="absolute top-4 right-4 w-80 z-20">
            <div class="bg-base-100 rounded-lg shadow-lg overflow-hidden border border-base-300">
              <TopologyDetails
                element={selectedElement}
                elementType={selectedElement && selectedElement.intf ? 'device' : 'interface'}
                onClose={closeDetailsPanel}
              />
            </div>
          </div>
        {/if}
      </div>
      
    {/if}
  </div>
</AppLayout>

<style>
  /* Fix dropdown positioning */
  .dropdown-content {
    position: absolute;
    right: 0;
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1);
  }
  
  @media (max-width: 640px) {
    .dropdown-content {
      width: calc(100vw - 1rem);
      max-width: 100%;
    }
  }
  
  /* Improved dropdown styling for dark mode */
  :global([data-theme="dark"]) .dropdown-content {
    background-color: hsl(var(--b1));
    border-color: rgba(255, 255, 255, 0.1);
  }
  
  /* Only modify padding for topology page without affecting iOS fixes */
  .topology-page-container {
    padding: 0 !important;
  }
  
  /* Fix controls position for iOS */
  @supports (-webkit-touch-callout: none) {
    .topology-page-container .h-\[calc\(100vh-13rem\)\] {
      height: calc(100vh - 13rem - 80px) !important;
    }
  }
</style>