import { invoke } from "@tauri-apps/api/core";

export async function cleanupDashboardResources() {
  console.log("Starting dashboard resources cleanup");
  
  try {
    await invoke("clear_traffic_cache").catch(err => {
      console.error("Error clearing traffic cache:", err);
    });
    await invoke("stop_log_polling").catch(err => {
      console.error("Error stopping log polling:", err);
    });

    console.log("Dashboard resources cleanup completed");
    return true;
  } catch (error) {
    console.error("Error during dashboard cleanup:", error);
    return false;
  }
}

export function registerLogoutCleanup(authStore) {
  const unsubscribe = authStore.subscribe($authStore => {
    if (!$authStore.isLoggedIn && $authStore.configured) {
      cleanupDashboardResources();
    }
  });
  
  return unsubscribe;
}