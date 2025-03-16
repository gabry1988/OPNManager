<script lang="ts">
  import { createEventDispatcher } from "svelte";
  import {
    mdiAccountOutline,
    mdiKey,
    mdiKeyLink,
    mdiWeb,
    mdiNumeric,
    mdiCheckCircleOutline,
    mdiChevronRight,
    mdiChevronLeft,
    mdiInformationOutline,
    mdiWallFire,
    mdiLanConnect,
    mdiLanDisconnect,
    mdiLoading,
  } from "@mdi/js";
  import { invoke } from "@tauri-apps/api/core";

  export let profileName = "Default";
  export let apiKey = "";
  export let apiSecret = "";
  export let apiUrl = "";
  export let port = 443;
  export let pin = "";

  const dispatch = createEventDispatcher();

  // Setup step tracking
  let currentStep = 0;
  const totalSteps = 7; // Profile name, API key, API secret, URL, port, PIN, and review

  // Connection test state
  let isTestingConnection = false;
  let connectionTestStatus: "none" | "success" | "error" = "none";
  let connectionErrorMessage = "";

  // Validation states
  let errors = {
    profileName: "",
    apiKey: "",
    apiSecret: "",
    apiUrl: "",
    port: "",
    pin: "",
  };

  // Step validation functions
  function validateCurrentStep(): boolean {
    resetErrors();

    switch (currentStep) {
      case 0: // Profile Name
        if (!profileName.trim()) {
          errors.profileName = "Profile name is required";
          return false;
        }
        break;
      case 1: // API Key
        if (!apiKey.trim()) {
          errors.apiKey = "API key is required";
          return false;
        }
        break;
      case 2: // API Secret
        if (!apiSecret.trim()) {
          errors.apiSecret = "API secret is required";
          return false;
        }
        break;
      case 3: // Firewall Address
        try {
          // Basic URL validation
          if (!apiUrl.trim()) {
            errors.apiUrl = "Firewall address is required";
            return false;
          }

          // Ensure URL has https:// prefix
          if (!apiUrl.startsWith("https://")) {
            errors.apiUrl = "URL must start with https://";
            return false;
          }

          new URL(apiUrl);
        } catch (e) {
          errors.apiUrl = "Please enter a valid URL";
          return false;
        }
        break;
      case 4: // Port
        if (isNaN(Number(port)) || Number(port) < 1 || Number(port) > 65535) {
          errors.port = "Please enter a valid port number (1-65535)";
          return false;
        }
        break;
      case 5: // PIN
        if (!pin.trim()) {
          errors.pin = "PIN is required";
          return false;
        }
        if (!/^\d+$/.test(pin)) {
          errors.pin = "PIN must contain only numbers";
          return false;
        }
        if (pin.length < 4) {
          errors.pin = "PIN should be at least 4 digits";
          return false;
        }
        break;
    }

    return true;
  }

  function resetErrors() {
    errors = {
      profileName: "",
      apiKey: "",
      apiSecret: "",
      apiUrl: "",
      port: "",
      pin: "",
    };
  }

  function handleNext() {
    if (validateCurrentStep()) {
      if (currentStep < totalSteps - 1) {
        currentStep++;
      }
    }
  }

  function handleBack() {
    if (currentStep > 0) {
      currentStep--;
    }
  }

  function handleSubmit() {
    if (validateCurrentStep()) {
      dispatch("submit", {
        profileName,
        apiKey,
        apiSecret,
        apiUrl,
        port: Number(port),
        pin,
      });
    }
  }

  function handlePortChange(event: Event) {
    const input = event.target as HTMLInputElement;
    const value = input.value;
    const portNum = parseInt(value);

    if (!isNaN(portNum)) {
      port = Math.min(Math.max(portNum, 1), 65535);
      input.value = port.toString();
    } else {
      port = 443;
      input.value = "443";
    }
  }

  async function testConnection() {
    connectionTestStatus = "none";
    connectionErrorMessage = "";
    isTestingConnection = true;

    try {
      // Ensure URL is formatted correctly
      let formattedUrl = apiUrl;
      if (formattedUrl.endsWith("/")) {
        formattedUrl = formattedUrl.slice(0, -1);
      }

      const result = await invoke("test_api_connection", {
        apiKey,
        apiSecret,
        apiUrl: formattedUrl,
        port: Number(port),
      });

      // If we got here without an error, the connection was successful
      connectionTestStatus = "success";
    } catch (error) {
      connectionTestStatus = "error";
      if (error instanceof Error) {
        connectionErrorMessage = error.message;
      } else {
        connectionErrorMessage = String(error);
      }
    } finally {
      isTestingConnection = false;
    }
  }
</script>

<div class="mx-auto max-w-md p-4">
  <!-- Progress bar -->
  <div class="mb-5">
    <div class="flex justify-between text-sm mb-1">
      <span>Setup Progress</span>
      <span>{Math.round(((currentStep + 1) / totalSteps) * 100)}%</span>
    </div>
    <div class="w-full bg-base-200 rounded-full h-2">
      <div
        class="bg-primary h-2 rounded-full transition-all duration-300"
        style="width: {((currentStep + 1) / totalSteps) * 100}%"
      ></div>
    </div>
    <div class="text-xs text-center mt-1 text-gray-500">
      Step {currentStep + 1} of {totalSteps}
    </div>
  </div>

  <!-- Form -->
  <div class="card bg-base-100 shadow-lg">
    <div class="card-body">
      {#if currentStep === 0}
        <!-- Step 1: Profile Name -->
        <div class="animate-fadeIn">
          <div class="flex items-center gap-2 mb-4">
            <svg class="w-6 h-6 text-primary flex-shrink-0" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiAccountOutline} />
            </svg>
            <h2 class="card-title">Name Your Profile</h2>
          </div>

          <div class="alert alert-info mb-4">
            <svg class="w-5 h-5 flex-shrink-0" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiInformationOutline} />
            </svg>
            <span
              >OPNManager supports managing multiple firewalls using
              profiles.</span
            >
          </div>

          <div class="form-control mb-4">
            <label class="label" for="profileName">
              <span class="label-text">Profile Name</span>
            </label>
            <input
              id="profileName"
              bind:value={profileName}
              type="text"
              placeholder="e.g., Home Network, Office, Client Site"
              class="input input-bordered w-full {errors.profileName
                ? 'input-error'
                : ''}"
            />
            {#if errors.profileName}
              <label class="label">
                <span class="label-text-alt text-error"
                  >{errors.profileName}</span
                >
              </label>
            {:else}
              <label class="label">
                <span class="label-text-alt"
                  >Choose a descriptive name to identify this firewall</span
                >
              </label>
            {/if}
          </div>
        </div>
      {:else if currentStep === 1}
        <!-- Step 2: API Key -->
        <div class="animate-fadeIn">
          <div class="flex items-center gap-2 mb-4">
            <svg class="w-6 h-6 text-primary flex-shrink-0" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiKey} />
            </svg>
            <h2 class="card-title">API Key</h2>
          </div>

          <div class="alert alert-info mb-4">
            <svg class="w-5 h-5 flex-shrink-0" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiInformationOutline} />
            </svg>
            <span>API keys allow secure access to your OPNsense firewall.</span>
          </div>

          <div class="form-control mb-4">
            <label class="label" for="apiKey">
              <span class="label-text">API Key</span>
            </label>
            <input
              id="apiKey"
              bind:value={apiKey}
              type="text"
              placeholder="Enter your API key"
              class="input input-bordered w-full font-mono {errors.apiKey
                ? 'input-error'
                : ''}"
            />
            {#if errors.apiKey}
              <label class="label">
                <span class="label-text-alt text-error">{errors.apiKey}</span>
              </label>
            {/if}
          </div>

          <div class="bg-base-200 p-3 rounded-lg text-sm">
            <p class="font-medium">Where to find your API key:</p>
            <ol class="list-decimal list-inside space-y-1 ml-2 mt-1">
              <li>Log in to your OPNsense web interface</li>
              <li>Go to System → Access → Users</li>
              <li>Edit your user account</li>
              <li>Scroll down to the "API keys" section</li>
            </ol>
          </div>
        </div>
      {:else if currentStep === 2}
        <!-- Step 3: API Secret -->
        <div class="animate-fadeIn">
          <div class="flex items-center gap-2 mb-4">
            <svg class="w-6 h-6 text-primary flex-shrink-0" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiKeyLink} />
            </svg>
            <h2 class="card-title">API Secret</h2>
          </div>

          <div class="alert alert-info mb-4">
            <svg class="w-5 h-5 flex-shrink-0" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiInformationOutline} />
            </svg>
            <span
              >The API secret works together with your API key for
              authentication.</span
            >
          </div>

          <div class="form-control mb-4">
            <label class="label" for="apiSecret">
              <span class="label-text">API Secret</span>
            </label>
            <input
              id="apiSecret"
              bind:value={apiSecret}
              type="password"
              placeholder="Enter your API secret"
              class="input input-bordered w-full font-mono {errors.apiSecret
                ? 'input-error'
                : ''}"
            />
            {#if errors.apiSecret}
              <label class="label">
                <span class="label-text-alt text-error">{errors.apiSecret}</span
                >
              </label>
            {/if}
          </div>

          <div class="bg-base-200 p-3 rounded-lg text-sm">
            <p class="font-medium">Important:</p>
            <p class="mt-1">
              Your API key and secret provide administrative access to your
              firewall. This app will encrypt and store these credentials
              securely.
            </p>
          </div>
        </div>
      {:else if currentStep === 3}
        <!-- Step 4: Firewall Address -->
        <div class="animate-fadeIn">
          <div class="flex items-center gap-2 mb-4">
            <svg class="w-6 h-6 text-primary flex-shrink-0" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiWallFire} />
            </svg>
            <h2 class="card-title">Firewall Address</h2>
          </div>

          <div class="alert alert-info mb-4">
            <svg class="w-5 h-5 flex-shrink-0" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiInformationOutline} />
            </svg>
            <span
              >Enter the web address you use to access your OPNsense interface.</span
            >
          </div>

          <div class="form-control mb-4">
            <label class="label" for="apiUrl">
              <span class="label-text">Firewall Address</span>
            </label>
            <input
              id="apiUrl"
              bind:value={apiUrl}
              type="url"
              placeholder="https://192.168.1.1"
              class="input input-bordered w-full {errors.apiUrl
                ? 'input-error'
                : ''}"
            />
            {#if errors.apiUrl}
              <label class="label">
                <span class="label-text-alt text-error">{errors.apiUrl}</span>
              </label>
            {:else}
              <label class="label">
                <span class="label-text-alt"
                  >Enter only the base URL (no /api or other paths)</span
                >
              </label>
            {/if}
          </div>

          <div class="bg-base-200 p-3 rounded-lg text-sm">
            <p class="font-medium">Examples of valid firewall addresses:</p>
            <ul class="list-disc list-inside space-y-1 ml-2 mt-1">
              <li>https://192.168.1.1</li>
              <li>https://firewall.home.lan</li>
              <li>https://opnsense.mydomain.com</li>
            </ul>
          </div>
        </div>
      {:else if currentStep === 4}
        <!-- Step 5: Port -->
        <div class="animate-fadeIn">
          <div class="flex items-center gap-2 mb-4">
            <svg class="w-6 h-6 text-primary flex-shrink-0" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiWeb} />
            </svg>
            <h2 class="card-title">Port Number</h2>
          </div>

          <div class="alert alert-info mb-4">
            <svg class="w-5 h-5 flex-shrink-0" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiInformationOutline} />
            </svg>
            <span
              >Specify the port your OPNsense web interface uses. The default
              port for HTTPS is 443.</span
            >
          </div>

          <div class="form-control mb-4">
            <label class="label" for="port">
              <span class="label-text">Port</span>
            </label>
            <input
              id="port"
              bind:value={port}
              type="text"
              inputmode="numeric"
              on:blur={handlePortChange}
              placeholder="443"
              class="input input-bordered w-full {errors.port
                ? 'input-error'
                : ''}"
            />
            {#if errors.port}
              <label class="label">
                <span class="label-text-alt text-error">{errors.port}</span>
              </label>
            {:else}
              <label class="label">
                <span class="label-text-alt"
                  >Only change this for non-standard ports</span
                >
              </label>
            {/if}
          </div>
        </div>
      {:else if currentStep === 5}
        <!-- Step 6: Security PIN -->
        <div class="animate-fadeIn">
          <div class="flex items-center gap-2 mb-4">
            <svg class="w-6 h-6 text-primary flex-shrink-0" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiNumeric} />
            </svg>
            <h2 class="card-title">Security PIN</h2>
          </div>

          <div class="alert alert-info mb-4">
            <svg class="w-5 h-5 flex-shrink-0" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiInformationOutline} />
            </svg>
            <span
              >Create a numeric PIN to protect access to your firewall
              credentials.</span
            >
          </div>

          <div class="form-control mb-4">
            <label class="label" for="pin">
              <span class="label-text">Security PIN</span>
            </label>
            <input
              id="pin"
              bind:value={pin}
              type="password"
              inputmode="numeric"
              pattern="\d*"
              placeholder="Create a numeric PIN (at least 4 digits)"
              class="input input-bordered w-full {errors.pin
                ? 'input-error'
                : ''}"
            />
            {#if errors.pin}
              <label class="label">
                <span class="label-text-alt text-error">{errors.pin}</span>
              </label>
            {/if}
          </div>

          <div class="bg-base-200 p-3 rounded-lg text-sm">
            <p class="font-medium">About the Security PIN:</p>
            <p class="mt-1">
              This PIN is used to encrypt your API credentials on this device.
              It is <strong>not</strong> related to your OPNsense login credentials.
            </p>
          </div>
        </div>
      {:else if currentStep === 6}
        <!-- Step 7: Review & Confirm -->
        <div class="animate-fadeIn">
          <div class="flex items-center gap-2 mb-4">
            <svg class="w-6 h-6 text-primary flex-shrink-0" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiCheckCircleOutline} />
            </svg>
            <h2 class="card-title">Review & Confirm</h2>
          </div>

          <div class="alert alert-success mb-4">
            <svg class="w-5 h-5 flex-shrink-0" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiInformationOutline} />
            </svg>
            <span
              >Almost done! Please review your information before saving.</span
            >
          </div>

          <div class="bg-base-200 p-4 rounded-lg mb-4">
            <table class="w-full">
              <tbody>
                <tr>
                  <td class="py-1 font-medium">Profile Name:</td>
                  <td class="py-1">{profileName}</td>
                </tr>
                <tr>
                  <td class="py-1 font-medium">API Key:</td>
                  <td class="py-1 font-mono truncate"
                    >{apiKey.substring(0, 8)}●●●●●●●●</td
                  >
                </tr>
                <tr>
                  <td class="py-1 font-medium">API Secret:</td>
                  <td class="py-1 font-mono">●●●●●●●●●●●●</td>
                </tr>
                <tr>
                  <td class="py-1 font-medium">Firewall URL:</td>
                  <td class="py-1">{apiUrl}</td>
                </tr>
                <tr>
                  <td class="py-1 font-medium">Port:</td>
                  <td class="py-1">{port}</td>
                </tr>
                <tr>
                  <td class="py-1 font-medium">PIN:</td>
                  <td class="py-1">●●●●</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Test Connection -->
          <div class="mb-4">
            <button
              class="btn btn-secondary w-full mb-2"
              on:click={testConnection}
              disabled={isTestingConnection}
            >
              {#if isTestingConnection}
                <svg class="animate-spin h-5 w-5 mr-2" viewBox="0 0 24 24">
                  <path fill="currentColor" d={mdiLoading} />
                </svg>
                Testing Connection...
              {:else}
                <svg class="h-5 w-5 mr-2" viewBox="0 0 24 24">
                  <path fill="currentColor" d={mdiLanConnect} />
                </svg>
                Test Connection
              {/if}
            </button>

            {#if connectionTestStatus === "success"}
              <div class="alert alert-success">
                <svg class="h-5 w-5 flex-shrink-0" viewBox="0 0 24 24">
                  <path fill="currentColor" d={mdiLanConnect} />
                </svg>
                <span
                  >Connection successful! Your API credentials are valid.</span
                >
              </div>
            {:else if connectionTestStatus === "error"}
              <div class="alert alert-error">
                <svg class="h-5 w-5 flex-shrink-0" viewBox="0 0 24 24">
                  <path fill="currentColor" d={mdiLanDisconnect} />
                </svg>
                <span
                  >Connection failed. Please check your connection settings.</span
                >
              </div>
            {/if}
          </div>

          <div class="bg-base-200 p-3 rounded-lg text-sm">
            <p>
              Click "Save Configuration" to complete setup and start managing
              your OPNsense firewall.
            </p>
          </div>
        </div>
      {/if}

      <!-- Navigation buttons -->
      <div class="flex justify-between mt-6">
        {#if currentStep > 0}
          <button class="btn btn-outline" on:click={handleBack}>
            <svg class="w-5 h-5 mr-1" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiChevronLeft} />
            </svg>
            Back
          </button>
        {:else}
          <div></div>
          <!-- Empty div to maintain flex layout -->
        {/if}

        {#if currentStep < totalSteps - 1}
          <button class="btn btn-primary" on:click={handleNext}>
            Next
            <svg class="w-5 h-5 ml-1" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiChevronRight} />
            </svg>
          </button>
        {:else}
          <button
            class="btn btn-primary"
            on:click={handleSubmit}
            disabled={connectionTestStatus === "error" || isTestingConnection}
          >
            Save Configuration
          </button>
        {/if}
      </div>
    </div>
  </div>
</div>

<style>
  .animate-fadeIn {
    animation: fadeIn 0.3s ease-in-out;
  }

  @keyframes fadeIn {
    from {
      opacity: 0;
      transform: translateY(10px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  .animate-spin {
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    from {
      transform: rotate(0deg);
    }
    to {
      transform: rotate(360deg);
    }
  }
</style>