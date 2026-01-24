package collector

import (
	"os"
	"strconv"
	"strings"

	"github.com/furvur/server-monitor-agent/pkg/models"
)

// CollectLoad reads CPU load averages from /proc/loadavg
func CollectLoad() (models.LoadMetrics, error) {
	data, err := os.ReadFile("/proc/loadavg")
	if err != nil {
		return models.LoadMetrics{}, err
	}

	fields := strings.Fields(string(data))
	if len(fields) < 3 {
		return models.LoadMetrics{}, nil
	}

	load1, _ := strconv.ParseFloat(fields[0], 64)
	load5, _ := strconv.ParseFloat(fields[1], 64)
	load15, _ := strconv.ParseFloat(fields[2], 64)

	return models.LoadMetrics{
		Load1:  load1,
		Load5:  load5,
		Load15: load15,
	}, nil
}
