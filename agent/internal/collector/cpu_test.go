package collector

import (
	"fmt"
	"testing"

	"github.com/furvur/server-monitor-agent/pkg/models"
)

func TestParseCPULoad(t *testing.T) {
	tests := []struct {
		name     string
		content  string
		expected models.LoadMetrics
		hasError bool
	}{
		{
			name:    "valid loadavg",
			content: "0.52 1.23 0.89 1/234 12345\n",
			expected: models.LoadMetrics{
				Load1:  0.52,
				Load5:  1.23,
				Load15: 0.89,
			},
			hasError: false,
		},
		{
			name:    "high load",
			content: "12.50 8.75 6.25 5/500 99999\n",
			expected: models.LoadMetrics{
				Load1:  12.50,
				Load5:  8.75,
				Load15: 6.25,
			},
			hasError: false,
		},
		{
			name:     "empty content",
			content:  "",
			expected: models.LoadMetrics{},
			hasError: true,
		},
		{
			name:     "malformed content",
			content:  "not a valid loadavg\n",
			expected: models.LoadMetrics{},
			hasError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			load, err := parseCPULoadFromContent(tt.content)

			if tt.hasError {
				if err == nil {
					t.Errorf("expected error, got nil")
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			if load.Load1 != tt.expected.Load1 {
				t.Errorf("Load1: expected %f, got %f", tt.expected.Load1, load.Load1)
			}
			if load.Load5 != tt.expected.Load5 {
				t.Errorf("Load5: expected %f, got %f", tt.expected.Load5, load.Load5)
			}
			if load.Load15 != tt.expected.Load15 {
				t.Errorf("Load15: expected %f, got %f", tt.expected.Load15, load.Load15)
			}
		})
	}
}

// parseCPULoadFromContent parses /proc/loadavg content directly for testing
func parseCPULoadFromContent(content string) (models.LoadMetrics, error) {
	var load models.LoadMetrics
	var runningStr string

	n, err := fmt.Sscanf(content, "%f %f %f %s", &load.Load1, &load.Load5, &load.Load15, &runningStr)
	if err != nil || n < 3 {
		return models.LoadMetrics{}, fmt.Errorf("failed to parse loadavg: %v", err)
	}

	return load, nil
}
