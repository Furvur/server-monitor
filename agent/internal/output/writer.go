package output

import (
	"encoding/json"
	"os"
	"path/filepath"

	"github.com/furvur/server-monitor-agent/pkg/models"
)

const (
	DefaultOutputPath = "/var/lib/server-monitor/metrics.json"
)

// Writer handles atomic writes of metrics to a JSON file
type Writer struct {
	path string
}

// NewWriter creates a new Writer with the specified output path
func NewWriter(path string) *Writer {
	if path == "" {
		path = DefaultOutputPath
	}
	return &Writer{path: path}
}

// Write atomically writes metrics to the output file
func (w *Writer) Write(metrics models.AgentMetrics) error {
	// Ensure directory exists
	dir := filepath.Dir(w.path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}

	// Marshal to JSON with indentation for readability
	data, err := json.MarshalIndent(metrics, "", "  ")
	if err != nil {
		return err
	}

	// Write to temporary file first
	tmpPath := w.path + ".tmp"
	if err := os.WriteFile(tmpPath, data, 0644); err != nil {
		return err
	}

	// Atomic rename
	return os.Rename(tmpPath, w.path)
}

// Path returns the configured output path
func (w *Writer) Path() string {
	return w.path
}
