package collector

import (
	"os"
	"strconv"
	"strings"

	"github.com/furvur/server-monitor-agent/pkg/models"
)

// CollectUptime reads system uptime from /proc/uptime
func CollectUptime() (models.UptimeStats, error) {
	data, err := os.ReadFile("/proc/uptime")
	if err != nil {
		return models.UptimeStats{}, err
	}

	fields := strings.Fields(string(data))
	if len(fields) < 1 {
		return models.UptimeStats{}, nil
	}

	// First field is uptime in seconds (with decimal)
	uptimeFloat, err := strconv.ParseFloat(fields[0], 64)
	if err != nil {
		return models.UptimeStats{}, err
	}

	return models.UptimeStats{
		TotalSeconds: int(uptimeFloat),
	}, nil
}
