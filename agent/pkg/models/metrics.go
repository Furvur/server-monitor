package models

import "time"

// AgentMetrics is the top-level JSON structure written by the agent
type AgentMetrics struct {
	Version     string          `json:"version"`
	CollectedAt time.Time       `json:"collected_at"`
	Load        LoadMetrics     `json:"load"`
	Memory      MemoryStats     `json:"memory"`
	Disk        DiskStats       `json:"disk"`
	Swap        SwapStats       `json:"swap"`
	Network     NetworkStats    `json:"network"`
	Uptime      UptimeStats     `json:"uptime"`
	SystemInfo  SystemInfo      `json:"system_info"`
	Services    []ServiceStatus `json:"services,omitempty"`
}

type LoadMetrics struct {
	Load1  float64 `json:"load_1"`
	Load5  float64 `json:"load_5"`
	Load15 float64 `json:"load_15"`
}

type MemoryStats struct {
	TotalMB int `json:"total_mb"`
	UsedMB  int `json:"used_mb"`
	FreeMB  int `json:"free_mb"`
}

type DiskStats struct {
	TotalGB      float64 `json:"total_gb"`
	UsedGB       float64 `json:"used_gb"`
	FreeGB       float64 `json:"free_gb"`
	UsagePercent float64 `json:"usage_percent"`
}

type SwapStats struct {
	TotalMB int `json:"total_mb"`
	UsedMB  int `json:"used_mb"`
	FreeMB  int `json:"free_mb"`
}

type NetworkStats struct {
	BytesIn  uint64 `json:"bytes_in"`
	BytesOut uint64 `json:"bytes_out"`
}

type UptimeStats struct {
	TotalSeconds int `json:"total_seconds"`
}

type SystemInfo struct {
	OSName        string `json:"os_name"`
	OSVersion     string `json:"os_version"`
	KernelVersion string `json:"kernel_version"`
	Hostname      string `json:"hostname"`
	Architecture  string `json:"architecture"`
}

type ServiceStatus struct {
	Name       string            `json:"name"`
	IsRunning  bool              `json:"is_running"`
	Details    string            `json:"details,omitempty"`
	Containers []ContainerStatus `json:"containers,omitempty"`
}

type ContainerStatus struct {
	Name   string `json:"name"`
	State  string `json:"state"`
	Image  string `json:"image"`
	Status string `json:"status"`
}
