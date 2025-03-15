<script lang="ts">
  import { onMount } from "svelte";
  import { invoke } from "@tauri-apps/api/core";
  import { fade, fly } from "svelte/transition";
  import AppLayout from "../AppLayout.svelte";
  import { toasts } from "$lib/stores/toastStore";
  import { authStore } from "$lib/stores/authStore";
  import { fabStore, toggleFab, closeFab } from "$lib/stores/fabStore";
  import {
    mdiRefresh,
    mdiDelete,
    mdiDotsVertical,
    mdiClose,
    mdiMagnify,
    mdiIpNetwork,
    mdiIpNetworkOutline,
  } from "@mdi/js";

  // Updated interface to match our combined device struct with multiple IPs
  interface CombinedDevice {
    mac: string;
    ipv4_addresses: string[];
    ipv6_addresses: string[];
    intf: string;
    expired?: boolean;
    expires?: number;
    permanent?: boolean;
    device_type?: string;
    manufacturer: string;
    hostname: string;
    intf_description: string;
  }

  let devices: CombinedDevice[] = [];
  let filteredDevices: CombinedDevice[] = [];
  let isLoading = true;
  let selectedDevice: CombinedDevice | null = null;
  let isModalOpen = false;

  let filters = {
    ip: "",
    mac: "",
  };

  onMount(async () => {
    if ($authStore.isLoggedIn) {
      await fetchDevices();
    }
  });

  async function fetchDevices() {
    isLoading = true;
    try {
      devices = await invoke<CombinedDevice[]>("get_combined_devices");
      applyFilters();
    } catch (error) {
      console.error("Failed to fetch devices:", error);
      toasts.error("Failed to fetch devices. Please try again.");
    } finally {
      isLoading = false;
    }
  }

  function applyFilters() {
    filteredDevices = devices.filter((device) => {
      // Filter by IP (check both IPv4 and IPv6 addresses)
      const ipFilter = filters.ip.toLowerCase().trim();

      const ipv4Match =
        ipFilter === "" ||
        device.ipv4_addresses.some((ip) => ip.toLowerCase().includes(ipFilter));

      const ipv6Match =
        ipFilter === "" ||
        device.ipv6_addresses.some((ip) => ip.toLowerCase().includes(ipFilter));

      const ipMatch = ipv4Match || ipv6Match;

      // Filter by MAC
      const macMatch =
        filters.mac.toLowerCase().trim() === "" ||
        device.mac.toLowerCase().includes(filters.mac.toLowerCase().trim());

      return ipMatch && macMatch;
    });
  }

  async function handleFlushArpTable() {
    try {
      await invoke("flush_arp_table");
      toasts.success("ARP table flushed successfully");
      await fetchDevices();
    } catch (error) {
      console.error("Failed to flush ARP table:", error);
      toasts.error("Failed to flush ARP table. Please try again.");
    }
  }

  function openModal(device: CombinedDevice) {
    selectedDevice = device;
    isModalOpen = true;
  }

  function closeModal() {
    isModalOpen = false;
    selectedDevice = null;
  }

  function handleOutsideClick(event: MouseEvent) {
    const target = event.target as HTMLElement;
    if (!target.closest(".fab-container")) {
      closeFab();
    }
  }

  async function fetchDevicesAndCloseFab() {
    await fetchDevices();
    closeFab();
  }

  async function handleFlushArpTableAndCloseFab() {
    await handleFlushArpTable();
    closeFab();
  }

  $: {
    filters;
    if (devices.length > 0) {
      applyFilters();
    }
  }
</script>

<svelte:window on:click={handleOutsideClick} />

<AppLayout>
  <div class="max-w-6xl mx-auto">
    <h2 class="text-2xl font-bold mb-6">Devices</h2>

    {#if isLoading}
      <div class="text-center">
        <span class="loading loading-spinner loading-lg"></span>
        <p class="mt-4 text-base-content">Loading devices...</p>
      </div>
    {:else if filteredDevices.length === 0}
      <p class="text-base-content">No devices found.</p>
    {:else}
      <!-- Search filters - visible on all screen sizes -->
      <div class="bg-base-100 rounded-lg shadow p-4 mb-4">
        <h3 class="font-bold text-lg mb-3">Filters</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="text-sm font-medium mb-1 block">IP Address</label>
            <div class="flex items-center bg-base-200 rounded-md px-3 py-2">
              <svg
                class="w-5 h-5 mr-2 text-base-content opacity-70"
                viewBox="0 0 24 24"
              >
                <path fill="currentColor" d={mdiMagnify} />
              </svg>
              <input
                type="text"
                placeholder="Filter by IPv4 or IPv6"
                class="bg-transparent border-none focus:outline-none text-sm w-full"
                bind:value={filters.ip}
              />
            </div>
          </div>
          <div>
            <label class="text-sm font-medium mb-1 block">MAC Address</label>
            <div class="flex items-center bg-base-200 rounded-md px-3 py-2">
              <svg
                class="w-5 h-5 mr-2 text-base-content opacity-70"
                viewBox="0 0 24 24"
              >
                <path fill="currentColor" d={mdiMagnify} />
              </svg>
              <input
                type="text"
                placeholder="Filter by MAC address"
                class="bg-transparent border-none focus:outline-none text-sm w-full"
                bind:value={filters.mac}
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Mobile card view (shown on small screens) -->
      <div class="md:hidden space-y-4">
        {#each filteredDevices as device}
          <div
            class="card bg-base-100 shadow-md hover:shadow-lg transition-shadow duration-200 cursor-pointer"
            on:click={() => openModal(device)}
          >
            <div class="card-body p-4">
              <div class="space-y-1">
                <!-- IP Addresses -->
                {#if device.ipv4_addresses && device.ipv4_addresses.length > 0}
                  <div class="flex items-center flex-wrap gap-1">
                    <span class="badge badge-sm badge-primary">v4</span>
                    <span class="font-medium truncate"
                      >{device.ipv4_addresses[0]}</span
                    >
                    {#if device.ipv4_addresses.length > 1}
                      <span class="badge badge-sm badge-ghost"
                        >+{device.ipv4_addresses.length - 1}</span
                      >
                    {/if}
                  </div>
                {/if}

                {#if device.ipv6_addresses && device.ipv6_addresses.length > 0}
                  <div class="flex items-center flex-wrap gap-1">
                    <span class="badge badge-sm badge-secondary">v6</span>
                    <span
                      class="font-medium truncate text-xs max-w-[260px]"
                      title={device.ipv6_addresses[0]}
                    >
                      {device.ipv6_addresses[0]}
                    </span>
                    {#if device.ipv6_addresses.length > 1}
                      <span class="badge badge-sm badge-ghost"
                        >+{device.ipv6_addresses.length - 1}</span
                      >
                    {/if}
                  </div>
                {/if}
              </div>

              <div class="divider my-1"></div>

              <div class="grid grid-cols-2 gap-2 text-sm">
                <div>
                  <div class="opacity-70">MAC Address</div>
                  <div class="font-mono">{device.mac || "N/A"}</div>
                </div>
                <div>
                  <div class="opacity-70">Interface</div>
                  <div>{device.intf || "N/A"}</div>
                </div>
                {#if device.hostname}
                  <div class="col-span-2">
                    <div class="opacity-70">Hostname</div>
                    <div>{device.hostname}</div>
                  </div>
                {/if}
              </div>
            </div>
          </div>
        {/each}
      </div>

      <!-- Desktop table view (hidden on mobile) -->
      <div
        class="hidden md:block overflow-x-auto bg-base-100 rounded-lg shadow"
      >
        <table class="table w-full">
          <thead>
            <tr>
              <th>IP Address</th>
              <th>MAC Address</th>
              <th>Interface</th>
              <th>Hostname</th>
            </tr>
          </thead>
          <tbody>
            {#each filteredDevices as device}
              <tr
                class="hover:bg-base-200 transition-colors duration-200 cursor-pointer"
                on:click={() => openModal(device)}
              >
                <td class="py-4">
                  <div class="space-y-1">
                    <!-- IPv4 Addresses -->
                    {#if device.ipv4_addresses && device.ipv4_addresses.length > 0}
                      <!-- Only show the first IPv4 address in the table view -->
                      <div class="flex items-center">
                        <span class="badge badge-sm badge-primary mr-2">v4</span
                        >
                        {device.ipv4_addresses[0]}
                        {#if device.ipv4_addresses.length > 1}
                          <span class="badge badge-sm badge-ghost ml-2"
                            >+{device.ipv4_addresses.length - 1}</span
                          >
                        {/if}
                      </div>
                    {/if}

                    <!-- IPv6 Addresses - show first one only in table view -->
                    {#if device.ipv6_addresses && device.ipv6_addresses.length > 0}
                      <div class="flex items-center">
                        <span class="badge badge-sm badge-secondary mr-2"
                          >v6</span
                        >
                        <span
                          class="text-xs truncate max-w-[200px]"
                          title={device.ipv6_addresses[0]}
                        >
                          {device.ipv6_addresses[0]}
                        </span>
                        {#if device.ipv6_addresses.length > 1}
                          <span class="badge badge-sm badge-ghost ml-2"
                            >+{device.ipv6_addresses.length - 1}</span
                          >
                        {/if}
                      </div>
                    {/if}

                    {#if (!device.ipv4_addresses || device.ipv4_addresses.length === 0) && (!device.ipv6_addresses || device.ipv6_addresses.length === 0)}
                      <span class="opacity-50">No IP addresses</span>
                    {/if}
                  </div>
                </td>
                <td class="py-4 font-mono">
                  {device.mac || "N/A"}
                </td>
                <td class="py-4">
                  {device.intf || "N/A"}
                  <div class="text-xs opacity-70">
                    {device.intf_description || ""}
                  </div>
                </td>
                <td class="py-4">
                  {device.hostname || "Unknown"}
                </td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>
    {/if}
  </div>

  <!-- Floating Action Button -->
  <div class="fixed bottom-6 right-6 fab-container">
    <div class="relative">
      {#if $fabStore.isExpanded}
        <div transition:fade={{ duration: 200 }}>
          <button
            on:click={fetchDevicesAndCloseFab}
            class="fab-option btn btn-circle btn-primary absolute bottom-24 right-0"
            title="Refresh Devices"
            transition:fly={{ y: 20, duration: 200 }}
          >
            <svg class="w-6 h-6" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiRefresh} />
            </svg>
          </button>
          <button
            on:click={handleFlushArpTableAndCloseFab}
            class="fab-option btn btn-circle btn-secondary absolute bottom-44 right-0"
            title="Flush ARP Table"
            transition:fly={{ y: 20, duration: 200, delay: 50 }}
          >
            <svg class="w-6 h-6" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiDelete} />
            </svg>
          </button>
        </div>
      {/if}
      <button
        on:click={(e) => {
          e.stopPropagation();
          toggleFab();
        }}
        class="btn btn-circle btn-lg btn-primary shadow-lg"
      >
        <svg class="w-6 h-6" viewBox="0 0 24 24">
          <path
            fill="currentColor"
            d={$fabStore.isExpanded ? mdiClose : mdiDotsVertical}
          />
        </svg>
      </button>
    </div>
  </div>

  <!-- Modal -->
  {#if isModalOpen && selectedDevice}
    <div
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
    >
      <div class="bg-base-100 p-6 rounded-lg max-w-md w-full">
        <h3 class="text-lg font-bold mb-4">Device Details</h3>
        <div class="space-y-3">
          <!-- IPv4 Addresses -->
          {#if selectedDevice.ipv4_addresses && selectedDevice.ipv4_addresses.length > 0}
            <div>
              <strong
                >IPv4 {selectedDevice.ipv4_addresses.length > 1
                  ? "Addresses"
                  : "Address"}:</strong
              >
              <ul class="mt-1 ml-5 list-disc">
                {#each selectedDevice.ipv4_addresses as ipv4}
                  <li>{ipv4}</li>
                {/each}
              </ul>
            </div>
          {/if}

          <!-- IPv6 Addresses -->
          {#if selectedDevice.ipv6_addresses && selectedDevice.ipv6_addresses.length > 0}
            <div>
              <strong
                >IPv6 {selectedDevice.ipv6_addresses.length > 1
                  ? "Addresses"
                  : "Address"}:</strong
              >
              <ul class="mt-1 ml-5 list-disc">
                {#each selectedDevice.ipv6_addresses as ipv6}
                  <li class="break-all font-mono text-sm">{ipv6}</li>
                {/each}
              </ul>
            </div>
          {/if}

          <p>
            <strong>MAC Address:</strong>
            <span class="font-mono">{selectedDevice.mac || "N/A"}</span>
          </p>
          <p>
            <strong>Hostname:</strong>
            {selectedDevice.hostname || "Unknown"}
          </p>
          <p>
            <strong>Interface:</strong>
            {selectedDevice.intf || "N/A"} ({selectedDevice.intf_description ||
              "No description"})
          </p>
          <p>
            <strong>Manufacturer:</strong>
            {selectedDevice.manufacturer || "Unknown"}
          </p>

          {#if selectedDevice.permanent !== undefined}
            <p>
              <strong>Permanent Entry:</strong>
              {selectedDevice.permanent ? "Yes" : "No"}
            </p>
          {/if}
        </div>
        <div class="mt-6 flex justify-end">
          <button class="btn btn-primary" on:click={closeModal}>Close</button>
        </div>
      </div>
    </div>
  {/if}
</AppLayout>

<style>
  .btn-circle {
    @apply rounded-full w-14 h-14 p-0 grid place-items-center;
  }

  .btn-lg {
    @apply w-16 h-16;
  }

  .fab-option {
    @apply w-12 h-12;
  }
</style>
