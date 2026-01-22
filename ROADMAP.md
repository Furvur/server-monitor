# Roadmap

## Completed

### v0.1.0 - Initial Release

#### Core Infrastructure
- [x] SwiftUI-based macOS application
- [x] SSH-based server connections using system `ssh` command
- [x] Async/await architecture for concurrent server polling
- [x] Actor-based SSHService for thread-safe operations

#### Server Management
- [x] Add, edit, and delete server configurations
- [x] Test connection functionality
- [x] SSH key selection (ssh-agent or specific key file)
- [x] Custom port support
- [x] Server configuration persistence to JSON

#### System Metrics
- [x] CPU load monitoring (1/5/15 min averages)
- [x] Memory usage monitoring (total/used/free)
- [x] Disk usage monitoring (root filesystem)

#### Service Monitoring
- [x] Built-in service definitions for common services
- [x] Service categories: Containers, Web Servers, Databases, Cache, Runtimes, System
- [x] Multiple parse modes for different service types
- [x] Docker/Podman container status with expandable list
- [x] Auto-detect installed services

#### User Interface
- [x] Main window with sidebar navigation
- [x] Server detail view with metrics cards
- [x] Service status display with running/stopped indicators
- [x] Menu bar integration with popover
- [x] Settings window with tabs

### v0.2.0 - Historical Data & Charts

#### Settings Persistence
- [x] Persist refresh interval to UserDefaults
- [x] Add autoStartOnLaunch setting with persistence
- [x] Add historyRetentionHours setting with persistence
- [x] Respect autoStartOnLaunch on app launch

#### Historical Data
- [x] MetricSnapshot model for time-series data
- [x] HistoryService for JSON-based persistence
- [x] Per-server history files
- [x] Automatic cleanup based on retention policy
- [x] Configurable retention (1h, 6h, 24h, 7 days)

#### Charts
- [x] ServerChartsView with Swift Charts
- [x] CPU Load chart (3 lines: 1/5/15 min)
- [x] Memory Usage area chart
- [x] Disk Usage area chart
- [x] Time range picker (1h, 6h, 24h, 7d)
- [x] Overview/Charts tab switcher in detail view

#### UI Polish
- [x] Fix toggle switch artifacts in server form
- [x] Remove icons from services list for cleaner UI

---

## Planned

### v0.3.0 - Alerts & Notifications

- [ ] Threshold-based alerts (CPU > 80%, disk > 90%, etc.)
- [ ] macOS notifications for alerts
- [ ] Alert history log
- [ ] Per-server alert configuration
- [ ] Sound alerts option

### v0.4.0 - Enhanced Service Monitoring

- [ ] Custom service definitions
- [ ] Service groups/tags
- [ ] Service dependencies visualization
- [ ] Restart service action (with confirmation)
- [ ] Service logs viewer

### v0.5.0 - Multi-Server Features

- [ ] Server groups/folders
- [ ] Bulk actions (refresh all, etc.)
- [ ] Server comparison view
- [ ] Aggregate dashboard
- [ ] Server templates for quick setup

### v0.6.0 - Export & Reporting

- [ ] Export metrics to CSV
- [ ] Generate PDF reports
- [ ] Scheduled reports via email
- [ ] API endpoint for external integrations

### Future Considerations

- [ ] Touch Bar support
- [ ] Widgets for macOS desktop
- [ ] iCloud sync for configurations
- [ ] Team sharing features
- [ ] Custom SSH commands
- [ ] Process list monitoring
- [ ] Network statistics
- [ ] Log file tailing
