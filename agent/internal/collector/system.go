package collector

import (
	"bufio"
	"os"
	"runtime"
	"strings"

	"github.com/furvur/server-monitor-agent/pkg/models"
)

// CollectSystemInfo gathers OS and hardware information
func CollectSystemInfo() (models.SystemInfo, error) {
	info := models.SystemInfo{
		Architecture: runtime.GOARCH,
	}

	// Get hostname
	hostname, err := os.Hostname()
	if err == nil {
		info.Hostname = hostname
	}

	// Get kernel version from /proc/version
	if data, err := os.ReadFile("/proc/version"); err == nil {
		fields := strings.Fields(string(data))
		if len(fields) >= 3 {
			info.KernelVersion = fields[2]
		}
	}

	// Try to read /etc/os-release for OS info
	if file, err := os.Open("/etc/os-release"); err == nil {
		defer file.Close()
		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			line := scanner.Text()

			if strings.HasPrefix(line, "NAME=") {
				info.OSName = parseOSReleaseValue(line)
			} else if strings.HasPrefix(line, "VERSION_ID=") {
				info.OSVersion = parseOSReleaseValue(line)
			}
		}
	}

	// Map GOARCH to more familiar names
	switch info.Architecture {
	case "amd64":
		info.Architecture = "x86_64"
	case "arm64":
		info.Architecture = "aarch64"
	}

	return info, nil
}

// parseOSReleaseValue extracts the value from a KEY=VALUE or KEY="VALUE" line
func parseOSReleaseValue(line string) string {
	parts := strings.SplitN(line, "=", 2)
	if len(parts) != 2 {
		return ""
	}
	value := parts[1]
	// Remove surrounding quotes if present
	value = strings.Trim(value, "\"'")
	return value
}
