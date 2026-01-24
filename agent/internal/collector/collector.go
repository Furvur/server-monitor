package collector

import (
	"time"

	"github.com/furvur/server-monitor-agent/pkg/models"
)

// Version is set at build time via ldflags
var Version = "dev"

// Collector gathers all system metrics
type Collector struct {
	version string
}

// New creates a new Collector
func New(version string) *Collector {
	return &Collector{version: version}
}

// Collect gathers all metrics and returns an AgentMetrics struct
func (c *Collector) Collect() models.AgentMetrics {
	metrics := models.AgentMetrics{
		Version:     c.version,
		CollectedAt: time.Now().UTC(),
	}

	// Collect each metric type, ignoring individual errors
	// to ensure we return as much data as possible
	if load, err := CollectLoad(); err == nil {
		metrics.Load = load
	}

	if memory, err := CollectMemory(); err == nil {
		metrics.Memory = memory
	}

	if disk, err := CollectDisk(); err == nil {
		metrics.Disk = disk
	}

	if swap, err := CollectSwap(); err == nil {
		metrics.Swap = swap
	}

	if network, err := CollectNetwork(); err == nil {
		metrics.Network = network
	}

	if uptime, err := CollectUptime(); err == nil {
		metrics.Uptime = uptime
	}

	if sysInfo, err := CollectSystemInfo(); err == nil {
		metrics.SystemInfo = sysInfo
	}

	return metrics
}
