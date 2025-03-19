import { invoke } from "@tauri-apps/api/core";

/**
 * Performs a complete cleanup of all dashboard resources and polling
 * to ensure no background processes continue after navigation or logout
 */
export async function cleanupDashboardResources() {
  console.log("Starting dashboard resources cleanup");
  
  try {
    // Clear traffic data collection
    await invoke("clear_traffic_cache").catch(err => {
      console.error("Error clearing traffic cache:", err);
    });
    
    // Stop firewall logs polling
    await invoke("stop_log_polling").catch(err => {
      console.error("Error stopping log polling:", err);
    });
    
    // If other cleanup functions are needed, add them here

    console.log("Dashboard resources cleanup completed");
    return true;
  } catch (error) {
    console.error("Error during dashboard cleanup:", error);
    return false;
  }
}

/**
 * Use this in the authStore to ensure cleanup happens on logout
 */
export function registerLogoutCleanup(authStore) {
  // Subscribe to the authStore
  const unsubscribe = authStore.subscribe($authStore => {
    // If logged out state is detected
    if (!$authStore.isLoggedIn && $authStore.configured) {
      cleanupDashboardResources();
    }
  });
  
  return unsubscribe;
}