<script lang="ts">
  import { onMount, onDestroy, afterUpdate } from "svelte";
  import { invoke } from "@tauri-apps/api/core";
  import { page } from "$app/stores";
  import {
    mdiArrowUp,
    mdiArrowDown,
    mdiEyeOffOutline,
    mdiEyeOutline,
  } from "@mdi/js";

  const INTERFACE_COLORS = [
    "#3B82F6", // Blue
    "#10B981", // Green
    "#F97316", // Orange
    "#8B5CF6", // Purple
    "#EC4899", // Pink
    "#06B6D4", // Cyan
    "#EF4444", // Red
    "#F59E0B", // Amber
    "#14B8A6", // Teal
    "#22C55E", // Emerald
  ];

  const interfaceColorMap = new Map();
  let hiddenInterfaces = new Set();

  let trafficData = [];
  let interfaces = [];
  let dataFetchInterval;
  const chartHeight = 160;
  let maxBitsIn = 1000;
  let maxBitsOut = 1000;
  let chartWidth = 0;
  let inChartHeight = 0;
  let outChartHeight = 0;
  let chartContainer;
  let canvasIn;
  let canvasOut;
  let timeLabels = [];
  let dataCollection = [];
  let dataAge = 30;
  let redrawRequested = false;
  let isFirstDataLoad = true;
  let isLoadingNewData = true;
  let dataLoadTimeoutId;
  let dimensionsTimeoutIds = [];
  let progressInterval;

  $: if ($page) {
    if ($page.url.pathname === "/") {
      isLoadingNewData = true;
      resetVisualState();
    }
  }

  function formatBits(bits: number): string {
    if (bits === 0) return "0 bps";
    if (bits < 1000) return `${bits.toFixed(1)} bps`;
    if (bits < 1000000) return `${(bits / 1000).toFixed(1)} Kbps`;
    if (bits < 1000000000) return `${(bits / 1000000).toFixed(1)} Mbps`;
    return `${(bits / 1000000000).toFixed(1)} Gbps`;
  }

  function formatBitsForAxis(bits: number): string {
    if (bits === 0) return "0 b";
    if (bits < 1000) return `${bits.toFixed(0)} b`;
    if (bits < 1000000) return `${(bits / 1000).toFixed(0)} Kb`;
    if (bits < 1000000000) return `${(bits / 1000000).toFixed(1)} Mb`;
    return `${(bits / 1000000000).toFixed(1)} Gb`;
  }

  function getInterfaceColor(interfaceName: string): string {
    if (!interfaceColorMap.has(interfaceName)) {
      const colorIndex = interfaceColorMap.size % INTERFACE_COLORS.length;
      interfaceColorMap.set(interfaceName, INTERFACE_COLORS[colorIndex]);
    }

    return interfaceColorMap.get(interfaceName);
  }

  function toggleInterface(interfaceName: string) {
    console.log(
      `Before toggle: ${interfaceName} hidden: ${hiddenInterfaces.has(interfaceName)}`,
    );

    const newHiddenInterfaces = new Set(hiddenInterfaces);

    if (hiddenInterfaces.has(interfaceName)) {
      newHiddenInterfaces.delete(interfaceName);
      console.log(`Showing ${interfaceName}`);
    } else {
      newHiddenInterfaces.add(interfaceName);
      console.log(`Hiding ${interfaceName}`);
    }

    hiddenInterfaces = newHiddenInterfaces;
    console.log(
      `After toggle: Hidden interfaces: ${Array.from(hiddenInterfaces).join(", ")}`,
    );
    setTimeout(() => {
      drawCharts();
    }, 0);
  }

  function resetVisualState() {
    interfaces = [];
    interfaceColorMap.clear();
    hiddenInterfaces.clear();

    if (canvasIn && canvasOut) {
      const ctxIn = canvasIn.getContext("2d");
      const ctxOut = canvasOut.getContext("2d");
      if (ctxIn) ctxIn.clearRect(0, 0, canvasIn.width, canvasIn.height);
      if (ctxOut) ctxOut.clearRect(0, 0, canvasOut.width, canvasOut.height);
    }
  }

  async function fetchTrafficData() {
    try {
      await invoke("update_traffic_data");

      const data = await invoke<any[]>("get_traffic_graph_data");

      if (!data || data.length === 0) {
        console.log(
          "No traffic data available yet, waiting for more samples...",
        );
        return;
      }

      processAndAddData(data);

      if (isLoadingNewData && data.length > 0) {
        clearTimeout(dataLoadTimeoutId);
        dataLoadTimeoutId = setTimeout(() => {
          isLoadingNewData = false;
          isFirstDataLoad = false;
        }, 1000);
      }

      if (!redrawRequested) {
        redrawRequested = true;
        requestAnimationFrame(() => {
          drawCharts();
          redrawRequested = false;
        });
      }
    } catch (error) {
      console.error("Failed to fetch traffic data:", error);
    }
  }

  function resetGraphData() {
    dataCollection = [];
    interfaces = [];
    hiddenInterfaces.clear();
    interfaceColorMap.clear();

    if (canvasIn && canvasOut) {
      const ctxIn = canvasIn.getContext("2d");
      const ctxOut = canvasOut.getContext("2d");
      if (ctxIn) ctxIn.clearRect(0, 0, canvasIn.width, canvasIn.height);
      if (ctxOut) ctxOut.clearRect(0, 0, canvasOut.width, canvasOut.height);
    }

    console.log("Traffic graph data has been reset");
  }

  function updateChartDimensions() {
    if (chartContainer && canvasIn && canvasOut) {
      chartWidth = chartContainer.clientWidth || chartContainer.offsetWidth;
      if (!chartWidth || chartWidth < 10) {
        console.log("Chart width not properly detected, using fallback");
        const parentWidth = chartContainer.parentElement?.clientWidth;

        if (parentWidth && parentWidth > 10) {
          chartWidth = parentWidth - 40;
        } else {
          chartWidth = window.innerWidth - 80;
        }

        console.log("Using fallback width:", chartWidth);
      }

      inChartHeight = chartHeight;
      outChartHeight = chartHeight;
      canvasIn.width = chartWidth;
      canvasIn.height = inChartHeight;
      canvasOut.width = chartWidth;
      canvasOut.height = outChartHeight;

      drawCharts();

      console.log(
        "Chart dimensions updated - width:",
        chartWidth,
        "height:",
        chartHeight,
      );
    } else {
      console.log(
        "Cannot update chart dimensions - some elements not initialized yet",
      );
    }
  }

  function processAndAddData(data) {
    const latestDataByInterface = {};

    data.forEach((point) => {
      const interfaceName = point.interface_name;

      if (
        !latestDataByInterface[interfaceName] ||
        latestDataByInterface[interfaceName].timestamp < point.timestamp
      ) {
        latestDataByInterface[interfaceName] = point;
      }
    });

    const now = new Date();

    let totalBitsIn = 0;
    let totalBitsOut = 0;
    let activeInterfaces = new Set();

    Object.values(latestDataByInterface).forEach((point: any) => {
      totalBitsIn += point.bits_per_second_in;
      totalBitsOut += point.bits_per_second_out;
      activeInterfaces.add(point.interface_name);
    });

    const newInterfaces = Array.from(activeInterfaces);

    newInterfaces.forEach((iface) => {
      if (!interfaces.includes(iface)) {
        interfaces.push(iface);
      }
    });

    interfaces = interfaces.filter((iface) => activeInterfaces.has(iface));

    dataCollection.push({
      timestamp: now.getTime(),
      bitsIn: totalBitsIn,
      bitsOut: totalBitsOut,
      byInterface: { ...latestDataByInterface },
    });

    const maxPoints = dataAge;
    if (dataCollection.length > maxPoints) {
      dataCollection = dataCollection.slice(dataCollection.length - maxPoints);
    }
    updateMaxValues();
  }

  function updateMaxValues() {
    if (dataCollection.length === 0) return;

    let maxIn = 1000;
    let maxOut = 1000;

    dataCollection.forEach((point) => {
      if (point.bitsIn > maxIn) maxIn = point.bitsIn;
      if (point.bitsOut > maxOut) maxOut = point.bitsOut;
    });

    const newMaxIn = roundToNiceNumber(maxIn * 1.2);
    const newMaxOut = roundToNiceNumber(maxOut * 1.2);

    if (Math.abs(newMaxIn - maxBitsIn) / maxBitsIn > 0.1) {
      maxBitsIn = newMaxIn;
    }

    if (Math.abs(newMaxOut - maxBitsOut) / maxBitsOut > 0.1) {
      maxBitsOut = newMaxOut;
    }
  }

  function roundToNiceNumber(num) {
    if (num < 1000) return Math.ceil(num / 100) * 100;
    if (num < 10000) return Math.ceil(num / 1000) * 1000;
    if (num < 100000) return Math.ceil(num / 10000) * 10000;
    if (num < 1000000) return Math.ceil(num / 100000) * 100000;
    if (num < 10000000) return Math.ceil(num / 1000000) * 1000000;
    return Math.ceil(num / 10000000) * 10000000;
  }

  function drawCharts() {
    if (
      !canvasIn ||
      !canvasOut ||
      chartWidth === 0 ||
      inChartHeight === 0 ||
      outChartHeight === 0
    ) {
      return;
    }

    drawTrafficChart(canvasIn, inChartHeight, "in", maxBitsIn);
    drawTrafficChart(canvasOut, outChartHeight, "out", maxBitsOut);
  }

  function drawTrafficChart(canvas, height, direction, maxBits) {
    const ctx = canvas.getContext("2d");
    ctx.clearRect(0, 0, chartWidth, height);

    if (dataCollection.length < 2) return;
    const margin = {
      top: 10,
      right: 10,
      bottom: 5,
      left: 60,
    };

    const graphWidth = chartWidth - margin.left - margin.right;
    const graphHeight = height - margin.top - margin.bottom;
    ctx.strokeStyle = "#e5e7eb";
    ctx.lineWidth = 0.5;
    const yAxisSteps = 5;
    ctx.textAlign = "right";
    ctx.font = "10px system-ui, sans-serif";
    ctx.fillStyle = "#6b7280";

    for (let i = 0; i <= yAxisSteps; i++) {
      const y = margin.top + graphHeight - (i / yAxisSteps) * graphHeight;

      ctx.beginPath();
      ctx.moveTo(margin.left, y);
      ctx.lineTo(margin.left + graphWidth, y);
      ctx.stroke();
      const value = (i / yAxisSteps) * maxBits;
      ctx.fillText(formatBitsForAxis(value), margin.left - 5, y + 3);
    }

    const verticalLines = 6;
    const lineStep = graphWidth / verticalLines;

    ctx.textAlign = "center";
    for (let i = 0; i <= verticalLines; i++) {
      const x = margin.left + i * lineStep;

      ctx.beginPath();
      ctx.moveTo(x, margin.top);
      ctx.lineTo(x, margin.top + graphHeight);
      ctx.stroke();
    }

    interfaces.forEach((interfaceName) => {
      const color = getInterfaceColor(interfaceName);
      drawSingleInterfaceArea(
        ctx,
        interfaceName,
        direction,
        color,
        margin,
        graphWidth,
        graphHeight,
        maxBits,
      );
    });
  }

  function drawSingleInterfaceArea(
    ctx,
    interfaceName,
    direction,
    color,
    margin,
    graphWidth,
    graphHeight,
    maxBits,
  ) {
    if (hiddenInterfaces.has(interfaceName)) return;

    const points = [];

    dataCollection.forEach((dataPoint, index) => {
      let value = 0;

      if (dataPoint.byInterface[interfaceName]) {
        value =
          direction === "in"
            ? dataPoint.byInterface[interfaceName].bits_per_second_in
            : dataPoint.byInterface[interfaceName].bits_per_second_out;
      }

      const x =
        margin.left + (index / (dataCollection.length - 1)) * graphWidth;
      const y = margin.top + graphHeight - (value / maxBits) * graphHeight;

      points.push({ x, y, value });
    });

    if (points.length < 2) return;

    ctx.fillStyle = color + "80";
    ctx.beginPath();
    ctx.moveTo(points[0].x, margin.top + graphHeight);
    ctx.lineTo(points[0].x, points[0].y);

    for (let i = 0; i < points.length - 1; i++) {
      const xc = (points[i].x + points[i + 1].x) / 2;
      const yc = (points[i].y + points[i + 1].y) / 2;
      ctx.quadraticCurveTo(points[i].x, points[i].y, xc, yc);
    }

    ctx.quadraticCurveTo(
      points[points.length - 1].x,
      points[points.length - 1].y,
      points[points.length - 1].x,
      points[points.length - 1].y,
    );

    ctx.lineTo(points[points.length - 1].x, margin.top + graphHeight);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(points[0].x, points[0].y);

    for (let i = 0; i < points.length - 1; i++) {
      const xc = (points[i].x + points[i + 1].x) / 2;
      const yc = (points[i].y + points[i + 1].y) / 2;
      ctx.quadraticCurveTo(points[i].x, points[i].y, xc, yc);
    }

    ctx.quadraticCurveTo(
      points[points.length - 1].x,
      points[points.length - 1].y,
      points[points.length - 1].x,
      points[points.length - 1].y,
    );

    ctx.stroke();
  }

  function initializeChartDimensions() {
    dimensionsTimeoutIds.forEach((id) => clearTimeout(id));
    dimensionsTimeoutIds = [];

    updateChartDimensions();

    interfaces = [...interfaces];

    const delays = [50, 100, 300, 500, 1000, 2000];
    delays.forEach((delay) => {
      const id = setTimeout(() => {
        updateChartDimensions();
        if (delay >= 300) {
          interfaces = [...interfaces];
        }
      }, delay);
      dimensionsTimeoutIds.push(id);
    });
  }

  onMount(async () => {
    try {
      resetGraphData();

      isLoadingNewData = true;

      try {
        await invoke("clear_traffic_cache");
        console.log("Traffic cache cleared on mount");
      } catch (error) {
        console.error("Error clearing traffic cache:", error);
      }

      await fetchTrafficData();

      dataFetchInterval = setInterval(fetchTrafficData, 1000);

      initializeChartDimensions();

      window.addEventListener("resize", handleResize);

      if (window.screen && window.screen.orientation) {
        window.screen.orientation.addEventListener(
          "change",
          handleOrientationChange,
        );
      } else {
        window.addEventListener("orientationchange", handleOrientationChange);
      }
    } catch (error) {
      console.error("Error initializing traffic graph:", error);
    }
  });

  onDestroy(() => {
    // Clear all intervals
    if (dataFetchInterval) {
      clearInterval(dataFetchInterval);
      dataFetchInterval = null;
    }

    if (progressInterval) {
      clearInterval(progressInterval);
      progressInterval = null;
    }

    if (dataLoadTimeoutId) {
      clearTimeout(dataLoadTimeoutId);
      dataLoadTimeoutId = null;
    }

    // Clear all dimension-related timeouts
    dimensionsTimeoutIds.forEach((id) => clearTimeout(id));
    dimensionsTimeoutIds = [];

    // Remove event listeners
    window.removeEventListener("resize", handleResize);

    if (window.screen && window.screen.orientation) {
      window.screen.orientation.removeEventListener(
        "change",
        handleOrientationChange,
      );
    } else {
      window.removeEventListener("orientationchange", handleOrientationChange);
    }
    try {
      invoke("clear_traffic_cache").catch((err) => {
        console.error(
          "Error clearing traffic cache during component cleanup:",
          err,
        );
      });
    } catch (error) {
      console.error("Error invoking clear_traffic_cache:", error);
    }

    console.log("Traffic graph component fully cleaned up");
  });

  let resizeTimer;
  function handleResize() {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(() => {
      updateChartDimensions();
    }, 250);
  }

  function handleOrientationChange() {
    setTimeout(updateChartDimensions, 250);
  }

  afterUpdate(() => {
    if (chartWidth === 0 && chartContainer) {
      updateChartDimensions();
    }
  });
</script>

<div class="card bg-base-100 shadow-xl">
  <div class="card-body">
    <div class="flex justify-between items-center">
      <div>
        <h3 class="card-title text-lg mb-1">Traffic Graph</h3>
        <!-- Stable legend that doesn't jump around -->
        <div class="flex flex-wrap gap-3 min-h-8">
          <!-- Add min-height to ensure consistent display regardless of window size -->
          <div class="flex flex-wrap gap-3 min-h-8" style="min-height: 2rem;">
            {#if interfaces.length > 0 && !isLoadingNewData}
              <!-- Explicitly track the hiddenInterfaces set in the key to force updates -->
              {#key [interfaces, JSON.stringify(Array.from(hiddenInterfaces))]}
                {#each interfaces as interfaceName}
                  <button
                    class="flex items-center px-2 py-1 rounded-lg hover:bg-base-200 focus:outline-none min-w-[60px] min-h-[24px]"
                    on:click={() => toggleInterface(interfaceName)}
                    data-hidden={hiddenInterfaces.has(interfaceName)
                      ? "true"
                      : "false"}
                  >
                    <!-- Color dot with forced visibility -->
                    <div
                      class="w-3 h-3 rounded-full mr-2 flex-shrink-0"
                      style="background-color: {getInterfaceColor(
                        interfaceName,
                      )}; 
                               filter: {hiddenInterfaces.has(interfaceName)
                        ? 'grayscale(80%) brightness(50%)'
                        : 'none'};
                               display: block !important;"
                    ></div>

                    <!-- Interface name with forced styling -->
                    <span
                      class="text-xs font-medium flex-shrink-0"
                      style="text-decoration: {hiddenInterfaces.has(
                        interfaceName,
                      )
                        ? 'line-through'
                        : 'none'} !important;
                               color: {hiddenInterfaces.has(interfaceName)
                        ? '#6b7280'
                        : 'inherit'} !important;
                               display: inline !important;"
                    >
                      {interfaceName}
                    </span>

                    <!-- Indicator with forced visibility -->
                    <span
                      class="ml-1 text-xs flex-shrink-0"
                      style="color: {hiddenInterfaces.has(interfaceName)
                        ? '#ef4444'
                        : 'inherit'} !important;
                                   opacity: {hiddenInterfaces.has(interfaceName)
                        ? '1'
                        : '0.5'} !important;
                                   display: inline !important;"
                    >
                      {hiddenInterfaces.has(interfaceName) ? "✕" : "✓"}
                    </span>
                  </button>
                {/each}
              {/key}
            {/if}
          </div>
        </div>
      </div>
    </div>

    <div class="divider my-2"></div>

    <div
      bind:this={chartContainer}
      class="space-y-4"
      style="width: 100%; transition: height 0.3s ease-in-out;"
    >
      {#if isLoadingNewData || interfaces.length === 0}
        <div class="flex justify-center items-center h-80">
          <div class="text-center">
            <span class="loading loading-spinner loading-lg"></span>
            <p class="mt-4 text-base-content">
              {isFirstDataLoad
                ? "Collecting initial traffic data..."
                : "Refreshing traffic data..."}
            </p>
          </div>
        </div>
      {:else}
        <div>
          <div class="flex items-center">
            <h4 class="text-sm font-medium mb-1">Traffic In</h4>
            <svg class="w-4 h-4 ml-1 text-gray-500" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiArrowDown} />
            </svg>
          </div>
          <canvas
            bind:this={canvasIn}
            style="width: 100%; height: {chartHeight}px;"
          ></canvas>
        </div>
        <div>
          <div class="flex items-center">
            <h4 class="text-sm font-medium mb-1">Traffic Out</h4>
            <svg class="w-4 h-4 ml-1 text-gray-500" viewBox="0 0 24 24">
              <path fill="currentColor" d={mdiArrowUp} />
            </svg>
          </div>
          <canvas
            bind:this={canvasOut}
            style="width: 100%; height: {chartHeight}px;"
          ></canvas>
        </div>
      {/if}
    </div>
  </div>
</div>
