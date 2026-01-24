package service

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/furvur/server-monitor-agent/pkg/models"
)

// CheckDocker checks if Docker is installed and gets container status
func CheckDocker() (models.ServiceStatus, bool) {
	status := models.ServiceStatus{
		Name: "docker",
	}

	// Check if docker command exists
	if _, err := exec.LookPath("docker"); err != nil {
		return status, false
	}

	// Check if docker daemon is running
	cmd := exec.Command("docker", "info")
	if err := cmd.Run(); err != nil {
		status.IsRunning = false
		return status, true
	}

	status.IsRunning = true

	// Get container list
	cmd = exec.Command("docker", "ps", "-a", "--format", "{{.Names}}\t{{.State}}\t{{.Image}}\t{{.Status}}")
	output, err := cmd.Output()
	if err != nil {
		return status, true
	}

	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	if len(lines) == 0 || (len(lines) == 1 && lines[0] == "") {
		status.Details = "No containers"
		return status, true
	}

	var containers []models.ContainerStatus
	runningCount := 0

	for _, line := range lines {
		if line == "" {
			continue
		}

		parts := strings.Split(line, "\t")
		if len(parts) < 4 {
			continue
		}

		container := models.ContainerStatus{
			Name:   parts[0],
			State:  parts[1],
			Image:  parts[2],
			Status: parts[3],
		}
		containers = append(containers, container)

		if container.State == "running" {
			runningCount++
		}
	}

	status.Containers = containers
	status.Details = formatContainerCount(runningCount, len(containers))

	return status, true
}

func formatContainerCount(running, total int) string {
	if total == 0 {
		return "No containers"
	}
	return fmt.Sprintf("%d/%d running", running, total)
}
