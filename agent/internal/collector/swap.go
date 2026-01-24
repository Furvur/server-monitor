package collector

import (
	"bufio"
	"os"
	"strconv"
	"strings"

	"github.com/furvur/server-monitor-agent/pkg/models"
)

// CollectSwap reads swap stats from /proc/meminfo
func CollectSwap() (models.SwapStats, error) {
	file, err := os.Open("/proc/meminfo")
	if err != nil {
		return models.SwapStats{}, err
	}
	defer file.Close()

	var totalKB, freeKB int64

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		fields := strings.Fields(line)
		if len(fields) < 2 {
			continue
		}

		value, _ := strconv.ParseInt(fields[1], 10, 64)

		switch fields[0] {
		case "SwapTotal:":
			totalKB = value
		case "SwapFree:":
			freeKB = value
		}
	}

	totalMB := int(totalKB / 1024)
	freeMB := int(freeKB / 1024)
	usedMB := totalMB - freeMB

	return models.SwapStats{
		TotalMB: totalMB,
		UsedMB:  usedMB,
		FreeMB:  freeMB,
	}, nil
}
