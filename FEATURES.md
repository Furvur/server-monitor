# Features

## Core Monitoring

### System Metrics
- **CPU Load** - 1, 5, and 15 minute load averages parsed from `uptime`
- **Memory Usage** - Total, used, and free memory via `free -m`
- **Disk Usage** - Storage consumption for root filesystem via `df -h`

### Service Monitoring
- Monitor the status of services running on your servers
- Supports multiple service categories:
  - **Containers** - Docker, Podman (with individual container status)
  - **Web Servers** - Nginx, Apache, Caddy
  - **Databases** - PostgreSQL, MySQL, MongoDB, SQLite
  - **Cache & Queues** - Redis, Memcached, RabbitMQ, Sidekiq
  - **Runtimes** - PM2 (Node.js), Puma, Unicorn, Gunicorn
  - **System** - SSH, Cron, UFW Firewall, Fail2ban

### Service Detection
- **Auto-detect Services** - Automatically discover installed services on a server
- Uses `command -v` to check for installed binaries
- One-click to enable detected services for monitoring

## User Interface

### Main Window
- **Server List Sidebar** - All configured servers with status indicators
- **Server Detail View** - Detailed metrics and service status
- **Overview Tab** - Current metrics with visual progress bars
- **Charts Tab** - Historical data visualization

### Menu Bar
- Quick access popover showing all servers
- Status at a glance without opening the main window
- Refresh, settings, and quit controls
- Can be enabled/disabled in settings

### Settings
- **Servers Tab** - Add, edit, and remove server configurations
- **General Tab** - Appearance, monitoring, and history settings

## Historical Data & Charts

### Data Collection
- Metrics recorded after each refresh cycle
- Stored as JSON files per server
- Automatic cleanup based on retention policy

### Retention Options
- 1 hour (~120 data points at 30s interval)
- 6 hours (~720 data points)
- 24 hours (~2,880 data points)
- 7 days (~20,160 data points)

### Charts (Swift Charts)
- **CPU Load Chart** - Three lines showing 1/5/15 minute averages
- **Memory Usage Chart** - Area chart showing usage percentage over time
- **Disk Usage Chart** - Area chart showing disk consumption over time
- **Time Range Picker** - View 1h, 6h, 24h, or 7d of history

## Server Agent (Optional)

### Overview
An optional Go-based agent can be installed on Linux servers for more efficient metric collection. Instead of executing 10+ SSH commands per refresh, the agent reads directly from `/proc` and the app fetches metrics with a single `cat` command.

### Agent Features
- **Efficient Collection** - Reads directly from `/proc/loadavg`, `/proc/meminfo`, etc.
- **Cross-Platform** - Supports Linux amd64 and arm64 architectures
- **Automatic Updates** - App detects outdated agents and offers one-click updates
- **Systemd Integration** - Runs as a system service with auto-restart
- **Atomic Writes** - Metrics written atomically to prevent partial reads

### Installation
- One-click install from the macOS app
- Automatic architecture detection
- Progress indicator with detailed status
- No manual server configuration required

### Metrics Collected by Agent
- CPU load (1/5/15 minute averages)
- Memory usage (total, used, free)
- Disk usage (root filesystem)
- Swap usage
- Network I/O (bytes in/out)
- System uptime
- OS and kernel information
- Docker container status
- Systemd service status

### Agent Paths
- Binary: `/usr/local/bin/server-monitor-agent`
- Metrics: `/var/lib/server-monitor/metrics.json`
- Service: `/etc/systemd/system/server-monitor-agent.service`

## Connection & Security

### SSH Configuration
- Standard SSH connection via system `ssh` command
- Support for custom ports
- SSH key selection (specific key or ssh-agent)
- Batch mode for non-interactive connections
- Auto-accept new host keys

### Server Management
- Add/edit/delete servers
- Test connection before saving
- Enable/disable individual servers
- Per-server service configuration

## Settings Persistence

All settings are automatically saved and restored:
- **Refresh Interval** - How often to poll servers (15s, 30s, 1m, 5m)
- **Auto-start Monitoring** - Begin monitoring on app launch
- **History Retention** - How long to keep historical data
- **Menu Bar Visibility** - Show/hide menu bar icon
- **Server Configurations** - All server connection details

## iCloud Sync

- **Server Configuration Sync** - Sync server configurations across devices via iCloud
- **Automatic Merging** - Intelligently merges local and cloud configurations
- **Enable/Disable** - Can be toggled in settings
- **Requires iCloud** - User must be signed into iCloud

## Technical Details

### Architecture
- Native SwiftUI application
- `@MainActor` for thread-safe UI updates
- Async/await for concurrent server polling
- Actor-based SSH service for safe concurrent access

### Data Storage
- `~/Library/Application Support/ServerMonitor/servers.json` - Server configs
- `~/Library/Application Support/ServerMonitor/history/{server-id}.json` - Historical data
- `UserDefaults` - App preferences

### Supported Parse Modes
- `activeInactive` - systemctl status parsing
- `processCount` - pgrep process counting
- `dockerContainers` - Docker/Podman container list parsing
- `lineCount` - Count output lines
- `exitCode` - Command success/failure
- `custom` - Generic non-empty output check
