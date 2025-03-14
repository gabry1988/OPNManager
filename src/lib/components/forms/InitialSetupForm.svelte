<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { mdiInformationOutline } from '@mdi/js';

  export let profileName = "Default";
  export let apiKey = "";
  export let apiSecret = "";
  export let apiUrl = "";
  export let port = 443;
  export let pin = "";
  
  let showHelpModal = false;

  const dispatch = createEventDispatcher();

  function handleSubmit() {
    if (!/^\d+$/.test(pin)) {
      dispatch('error', { message: "PIN must contain only numbers." });
      return;
    }
    dispatch('submit', { 
      profileName, 
      apiKey, 
      apiSecret, 
      apiUrl, 
      port: Number(port), 
      pin 
    });
  }
  
  function toggleHelpModal() {
    showHelpModal = !showHelpModal;
  }
</script>

<form on:submit|preventDefault={handleSubmit} class="space-y-4 p-4">
  <div class="alert alert-info mb-6 shadow-lg">
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
    </svg>
    <div>
      <p>Thanks for using OPNsense Manager! Let's get you set up with your first connection.</p>
      <button class="btn btn-sm btn-ghost mt-1" on:click={toggleHelpModal}>
        Need help?
      </button>
    </div>
  </div>

  <div class="form-control">
    <label class="label" for="profileName">
      <span class="label-text">Profile Name</span>
    </label>
    <input id="profileName" bind:value={profileName} type="text" placeholder="Enter Profile Name" class="input input-bordered w-full" required />
  </div>

  <div class="form-control">
    <label class="label" for="apiKey">
      <span class="label-text">API Key</span>
      <span class="label-text-alt text-primary cursor-pointer" on:click={toggleHelpModal}>What's this?</span>
    </label>
    <input id="apiKey" bind:value={apiKey} type="text" placeholder="Enter API Key" class="input input-bordered w-full" required />
  </div>

  <div class="form-control">
    <label class="label" for="apiSecret">
      <span class="label-text">API Secret</span>
    </label>
    <input id="apiSecret" bind:value={apiSecret} type="password" placeholder="Enter API Secret" class="input input-bordered w-full" required />
  </div>

  <div class="form-control">
    <label class="label" for="apiUrl">
      <span class="label-text">Firewall Address</span>
      <span class="label-text-alt text-primary cursor-pointer" on:click={toggleHelpModal}>What to enter?</span>
    </label>
    <input id="apiUrl" bind:value={apiUrl} type="url" placeholder="https://192.168.1.1" class="input input-bordered w-full" required />
    <label class="label">
      <span class="label-text-alt">Enter the full URL to your firewall, including https://</span>
    </label>
  </div>

  <div class="form-control">
    <label class="label" for="port">
      <span class="label-text">Port</span>
    </label>
    <input id="port" bind:value={port} type="number" placeholder="Enter Port" class="input input-bordered w-full" required />
  </div>

  <div class="form-control">
    <label class="label" for="pin">
      <span class="label-text">Create Security PIN</span>
      <span class="label-text-alt text-primary cursor-pointer" on:click={toggleHelpModal}>Why do I need this?</span>
    </label>
    <input 
      id="pin"
      bind:value={pin}
      type="password"
      inputmode="numeric"
      pattern="\d*"
      placeholder="Create a numeric PIN"
      class="input input-bordered w-full"
      required
    />
    <label class="label">
      <span class="label-text-alt">This PIN will encrypt your API credentials on this device</span>
    </label>
  </div>

  <div class="form-control mt-6">
    <button type="submit" class="btn btn-primary w-full">
      Save Configuration
    </button>
  </div>
</form>

<!-- Help Modal -->
{#if showHelpModal}
  <div class="modal modal-open">
    <div class="modal-box">
      <h3 class="font-bold text-lg mb-4">Setting Up OPNsense Manager</h3>
      
      <div class="space-y-4">
        <p>
          To connect to your OPNsense firewall, you'll need the following information:
        </p>

        <div class="space-y-2">
          <h4 class="font-medium">API Key & Secret</h4>
          <p class="text-sm">
            These are credentials you generate in your OPNsense web interface:
          </p>
          <ol class="list-decimal list-inside text-sm ml-2 space-y-1">
            <li>Log in to your OPNsense web interface</li>
            <li>Go to System → Access → Users</li>
            <li>Edit your user and scroll to "API keys"</li>
            <li>Create a key and copy both the key and secret</li>
          </ol>
        </div>

        <div class="space-y-2">
          <h4 class="font-medium">Firewall Address</h4>
          <p class="text-sm">
            This is the web address you use to access your OPNsense interface, for example:
          </p>
          <ul class="list-disc list-inside text-sm ml-2">
            <li>https://192.168.1.1</li>
            <li>https://firewall.mydomain.com</li>
          </ul>
          <p class="text-sm mt-1">
            <strong>Do not add /api or other paths</strong> — just the base URL with https://.
          </p>
        </div>

        <div class="space-y-2">
          <h4 class="font-medium">Security PIN</h4>
          <p class="text-sm">
            This PIN is used to encrypt your API credentials on this device for security. You'll need to enter it when accessing the app. It is <strong>not</strong> related to your OPNsense credentials.
          </p>
        </div>
      </div>

      <div class="modal-action">
        <button class="btn" on:click={toggleHelpModal}>Close</button>
      </div>
    </div>
  </div>
{/if}