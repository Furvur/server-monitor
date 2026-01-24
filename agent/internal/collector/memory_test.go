package collector

import (
	"strings"
	"testing"

	"github.com/furvur/server-monitor-agent/pkg/models"
)

func TestParseMemoryFromContent(t *testing.T) {
	tests := []struct {
		name     string
		content  string
		expected models.MemoryStats
	}{
		{
			name: "typical meminfo",
			content: `MemTotal:        8174532 kB
MemFree:         1234567 kB
MemAvailable:    4567890 kB
Buffers:          123456 kB
Cached:          2345678 kB
SwapCached:            0 kB
Active:          3456789 kB
Inactive:        2345678 kB
`,
			expected: models.MemoryStats{
				TotalMB: 7982,
				FreeMB:  1205,
				UsedMB:  6777,
			},
		},
		{
			name:     "empty content",
			content:  "",
			expected: models.MemoryStats{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mem := parseMemoryFromContent(tt.content)

			// Allow some tolerance for rounding
			if abs(mem.TotalMB-tt.expected.TotalMB) > 1 {
				t.Errorf("TotalMB: expected ~%d, got %d", tt.expected.TotalMB, mem.TotalMB)
			}
			if abs(mem.FreeMB-tt.expected.FreeMB) > 1 {
				t.Errorf("FreeMB: expected ~%d, got %d", tt.expected.FreeMB, mem.FreeMB)
			}
			if abs(mem.UsedMB-tt.expected.UsedMB) > 1 {
				t.Errorf("UsedMB: expected ~%d, got %d", tt.expected.UsedMB, mem.UsedMB)
			}
		})
	}
}

func abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}

// parseMemoryFromContent parses /proc/meminfo content directly for testing
func parseMemoryFromContent(content string) models.MemoryStats {
	var mem models.MemoryStats

	lines := strings.Split(content, "\n")
	for _, line := range lines {
		if line == "" {
			continue
		}

		parts := strings.Fields(line)
		if len(parts) < 2 {
			continue
		}

		name := strings.TrimSuffix(parts[0], ":")
		value := parseInt(parts[1]) / 1024 // Convert KB to MB

		switch name {
		case "MemTotal":
			mem.TotalMB = value
		case "MemFree":
			mem.FreeMB = value
		}
	}

	mem.UsedMB = mem.TotalMB - mem.FreeMB

	return mem
}

func parseInt(s string) int {
	var val int
	for _, c := range s {
		if c < '0' || c > '9' {
			break
		}
		val = val*10 + int(c-'0')
	}
	return val
}
