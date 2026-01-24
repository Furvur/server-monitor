package collector

import (
	"bufio"
	"os"
	"strconv"
	"strings"

	"github.com/furvur/server-monitor-agent/pkg/models"
)

// CollectNetwork reads network stats from /proc/net/dev
func CollectNetwork() (models.NetworkStats, error) {
	file, err := os.Open("/proc/net/dev")
	if err != nil {
		return models.NetworkStats{}, err
	}
	defer file.Close()

	var totalBytesIn, totalBytesOut uint64

	scanner := bufio.NewScanner(file)
	lineNum := 0
	for scanner.Scan() {
		lineNum++
		// Skip header lines
		if lineNum <= 2 {
			continue
		}

		line := scanner.Text()

		// Split on colon to get interface name and stats
		parts := strings.SplitN(line, ":", 2)
		if len(parts) != 2 {
			continue
		}

		iface := strings.TrimSpace(parts[0])

		// Skip loopback and virtual interfaces
		if iface == "lo" || strings.HasPrefix(iface, "veth") ||
			strings.HasPrefix(iface, "docker") || strings.HasPrefix(iface, "br-") {
			continue
		}

		// Parse stats
		fields := strings.Fields(parts[1])
		if len(fields) < 10 {
			continue
		}

		// Field 0: bytes received
		// Field 8: bytes transmitted
		bytesIn, _ := strconv.ParseUint(fields[0], 10, 64)
		bytesOut, _ := strconv.ParseUint(fields[8], 10, 64)

		totalBytesIn += bytesIn
		totalBytesOut += bytesOut
	}

	return models.NetworkStats{
		BytesIn:  totalBytesIn,
		BytesOut: totalBytesOut,
	}, nil
}
