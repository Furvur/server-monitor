package collector

import (
	"bufio"
	"os"
	"strconv"
	"strings"

	"github.com/furvur/server-monitor-agent/pkg/models"
)

// CollectMemory reads memory stats from /proc/meminfo
func CollectMemory() (models.MemoryStats, error) {
	file, err := os.Open("/proc/meminfo")
	if err != nil {
		return models.MemoryStats{}, err
	}
	defer file.Close()

	var totalKB, freeKB, availableKB, buffersKB, cachedKB int64

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		fields := strings.Fields(line)
		if len(fields) < 2 {
			continue
		}

		value, _ := strconv.ParseInt(fields[1], 10, 64)

		switch fields[0] {
		case "MemTotal:":
			totalKB = value
		case "MemFree:":
			freeKB = value
		case "MemAvailable:":
			availableKB = value
		case "Buffers:":
			buffersKB = value
		case "Cached:":
			cachedKB = value
		}
	}

	// Calculate used memory
	// If MemAvailable is present, use it for a more accurate "free" calculation
	// Otherwise, use MemFree + Buffers + Cached
	var freeMB int
	if availableKB > 0 {
		freeMB = int(availableKB / 1024)
	} else {
		freeMB = int((freeKB + buffersKB + cachedKB) / 1024)
	}

	totalMB := int(totalKB / 1024)
	usedMB := totalMB - freeMB

	return models.MemoryStats{
		TotalMB: totalMB,
		UsedMB:  usedMB,
		FreeMB:  freeMB,
	}, nil
}
