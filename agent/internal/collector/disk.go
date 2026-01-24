package collector

import (
	"syscall"

	"github.com/furvur/server-monitor-agent/pkg/models"
)

// CollectDisk reads disk usage for the root filesystem using statfs
func CollectDisk() (models.DiskStats, error) {
	var stat syscall.Statfs_t
	err := syscall.Statfs("/", &stat)
	if err != nil {
		return models.DiskStats{}, err
	}

	// Calculate sizes in bytes
	blockSize := uint64(stat.Bsize)
	totalBytes := stat.Blocks * blockSize
	freeBytes := stat.Bfree * blockSize
	availableBytes := stat.Bavail * blockSize // Available to non-root users

	// Use available (not free) for user-facing metrics
	usedBytes := totalBytes - freeBytes

	// Convert to GB
	totalGB := float64(totalBytes) / (1024 * 1024 * 1024)
	usedGB := float64(usedBytes) / (1024 * 1024 * 1024)
	freeGB := float64(availableBytes) / (1024 * 1024 * 1024)

	// Calculate usage percent
	var usagePercent float64
	if totalBytes > 0 {
		usagePercent = (float64(usedBytes) / float64(totalBytes)) * 100
	}

	return models.DiskStats{
		TotalGB:      round2(totalGB),
		UsedGB:       round2(usedGB),
		FreeGB:       round2(freeGB),
		UsagePercent: round2(usagePercent),
	}, nil
}

func round2(f float64) float64 {
	return float64(int(f*100)) / 100
}
