<script lang="ts">
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';
    import { invoke } from "@tauri-apps/api/core";
    import { authStore } from '$lib/stores/authStore';
  
    async function performLogout() {
      try {
        console.log("Starting cleanup processes...");

        await invoke("clear_traffic_cache").catch(err => {
          console.error("Error clearing traffic cache:", err);
        });

        await invoke("stop_log_polling").catch(err => {
          console.error("Error stopping log polling:", err);
        });

        await invoke("clear_pin").catch(err => {
          console.error("Error clearing PIN cache:", err);
        });
        
        console.log("Cleanup complete, updating auth state...");
        authStore.logout();
        setTimeout(() => {
          console.log("Redirecting to login page...");
          goto('/');
        }, 500);
        
      } catch (error) {
        console.error("Error during logout:", error);
        setTimeout(() => goto('/'), 500);
      }
    }
  
    onMount(() => {
      performLogout();
    });
  </script>
  
  <div class="min-h-screen flex flex-col items-center justify-center bg-base-200">
    <div class="text-center">
      <div class="loading loading-spinner loading-lg text-primary"></div>
      <h2 class="mt-8 text-2xl font-bold">Logging out...</h2>
      <p class="mt-2 text-base-content/70">Please wait while we clean up your session.</p>
    </div>
  </div>