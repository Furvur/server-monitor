package service

import (
	"os/exec"
	"strings"

	"github.com/furvur/server-monitor-agent/pkg/models"
)

// CheckSystemdService checks if a systemd service is active
func CheckSystemdService(serviceName string, displayName string) (models.ServiceStatus, bool) {
	status := models.ServiceStatus{
		Name: displayName,
	}

	// Check if systemctl exists
	if _, err := exec.LookPath("systemctl"); err != nil {
		return status, false
	}

	// Check if service is active
	cmd := exec.Command("systemctl", "is-active", serviceName)
	output, err := cmd.Output()

	result := strings.TrimSpace(string(output))
	status.IsRunning = err == nil && result == "active"

	return status, true
}

// CommonServices returns a list of common services to check
var CommonServices = []struct {
	SystemdName string
	DisplayName string
}{
	{"nginx", "nginx"},
	{"apache2", "apache"},
	{"httpd", "apache"},
	{"postgresql", "postgresql"},
	{"mysql", "mysql"},
	{"mariadb", "mariadb"},
	{"redis", "redis"},
	{"redis-server", "redis"},
	{"memcached", "memcached"},
	{"rabbitmq-server", "rabbitmq"},
}

// CheckCommonServices checks all common services and returns those that are installed
func CheckCommonServices() []models.ServiceStatus {
	var services []models.ServiceStatus
	checked := make(map[string]bool)

	for _, svc := range CommonServices {
		// Skip if we already checked this display name
		if checked[svc.DisplayName] {
			continue
		}

		status, installed := CheckSystemdService(svc.SystemdName, svc.DisplayName)
		if installed {
			services = append(services, status)
			checked[svc.DisplayName] = true
		}
	}

	return services
}
