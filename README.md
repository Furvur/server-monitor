# Server Monitor

A native macOS application for monitoring remote servers via SSH. Track CPU load, memory usage, disk space, and service status across multiple servers from your menu bar or a dedicated window.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Real-time Server Monitoring** - CPU load, memory, and disk usage at a glance
- **Service Status Tracking** - Monitor Docker containers, web servers, databases, and more
- **Menu Bar Integration** - Quick access to server stats without leaving your workflow
- **Historical Data & Charts** - Visualize metrics over time with Swift Charts
- **SSH-based** - Secure connections using your existing SSH keys
- **Auto-detection** - Automatically discover installed services on your servers

## Requirements

- macOS 14.0 or later
- SSH access to remote servers (key-based authentication)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Furvur/server-monitor.git
   ```

2. Open the project in Xcode:
   ```bash
   cd server-monitor
   open ServerMonitor.xcodeproj
   ```

3. Build and run (⌘R)

## Quick Start

1. **Add a Server** - Click the + button or go to Settings > Servers
2. **Enter Connection Details** - Host, username, port, and SSH key
3. **Select Services to Monitor** - Use auto-detect or manually select
4. **Start Monitoring** - The app will begin collecting metrics automatically

## Supported Services

| Category | Services |
|----------|----------|
| Containers | Docker, Podman |
| Web Servers | Nginx, Apache, Caddy |
| Databases | PostgreSQL, MySQL, MongoDB, SQLite |
| Cache & Queues | Redis, Memcached, RabbitMQ, Sidekiq |
| Runtimes | PM2, Puma, Unicorn, Gunicorn |
| System | SSH, Cron, UFW Firewall, Fail2ban |

## Configuration

Settings are persisted automatically and include:

- **Refresh Interval** - 15s, 30s, 1min, or 5min
- **Auto-start Monitoring** - Begin monitoring when the app launches
- **History Retention** - Keep historical data for 1h, 6h, 24h, or 7 days
- **Menu Bar** - Show/hide the menu bar icon

## Data Storage

- Server configurations: `~/Library/Application Support/ServerMonitor/servers.json`
- Historical metrics: `~/Library/Application Support/ServerMonitor/history/`

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
