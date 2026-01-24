# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Server Monitor is a native macOS application for monitoring remote servers via SSH. It tracks CPU load, memory usage, disk space, network traffic, and service status across multiple servers from the menu bar or a dedicated window.

**Requirements:** macOS 14.0+, Swift 5.9, Xcode

## Build & Run Commands

```bash
# Open project in Xcode
open ServerMonitor.xcodeproj

# Build from command line
xcodebuild -project ServerMonitor.xcodeproj -scheme ServerMonitor -configuration Debug build

# Run tests
xcodebuild -project ServerMonitor.xcodeproj -scheme ServerMonitor -configuration Debug test

# Run a specific test file
xcodebuild test -project ServerMonitor.xcodeproj -scheme ServerMonitor -only-testing:ServerMonitorTests/SSHServiceParsingTests
```

## Architecture

### App Structure
- **ServerMonitorApp.swift** - App entry point with `@NSApplicationDelegateAdaptor` for menu bar integration
- **AppDelegate** - Manages `NSStatusItem` for menu bar, `NSPopover` for quick access, and owns the shared `MonitorService`

### Core Services (in `Services/`)
- **MonitorService** (`@MainActor`) - Central state manager and orchestrator. Holds `@Published` servers array, stats dictionary, and settings. Coordinates SSH fetches and persists data to `~/Library/Application Support/ServerMonitor/`
- **SSHService** (`actor`) - Executes SSH commands via `/usr/bin/ssh` process, parses Linux/macOS system stats output. Contains parsing methods for uptime, memory, disk, network, swap, and system info
- **HistoryService** - Stores `MetricSnapshot` records for historical charting
- **iCloudSyncService** - Optional sync of server configurations via `NSUbiquitousKeyValueStore`

### Data Models (in `Models/`)
- **Server** - Connection config (host, port, username, sshKeyPath, enabledServices)
- **ServerStats** - Runtime metrics snapshot including `CPULoad`, `MemoryStats`, `DiskStats`, `SwapStats`, `NetworkStats`, `UptimeStats`, `SystemInfo`
- **ServiceDefinition** - Service monitoring config with `checkCommand` and `ServiceParseMode` enum
- **BuiltInServices** - Static catalog of pre-defined services (Docker, Nginx, PostgreSQL, Redis, etc.)
- **MetricSnapshot** - Timestamped metrics for history/charts

### Views (in `Views/`)
- **MainWindowView** - `NavigationSplitView` with sidebar server list and detail pane
- **MenuBarView** - Compact popover for menu bar access
- **SettingsView** - App preferences (refresh interval, history retention, iCloud sync)
- **ServerChartsView** - Swift Charts visualizations for historical metrics

### Design System (in `Design/`)
- **DesignSystem.swift** - Centralized design tokens (`DSColor`, `DSDarkTheme`, `DSTypography`, `DSSpacing`, `DSRadius`)
- **Candidates/** and **Choices/** - Design iteration files for UI components

## Key Patterns

### SSH Command Execution
`SSHService.buildCommand(for:)` constructs a combined shell command that outputs sections delimited by `===SECTION===` markers, which `parseStats()` then splits and processes per section.

### Service Monitoring
Services use `ServiceParseMode` to determine how command output maps to running/stopped status:
- `.activeInactive` - systemctl output
- `.processCount` - pgrep -c output
- `.dockerContainers` - docker ps with tab-separated format
- `.lineCount`, `.exitCode`, `.custom`

### State Management
`MonitorService` uses Combine's `@Published` properties. Views observe via `@EnvironmentObject`. The monitoring loop runs as a `Task` with configurable refresh intervals.

## Testing

Tests use Swift Testing framework (`import Testing`, `@Test` attribute, `#expect` assertions). Key test files:
- **SSHServiceTests.swift** - Parsing method unit tests (uptime, memory, disk, network, etc.)
- **ServerTests.swift**, **ServerStatsTests.swift** - Model tests
- **HistoryServiceTests.swift**, **MonitorServiceTests.swift** - Service logic tests

## Data Storage Locations

- Server configs: `~/Library/Application Support/ServerMonitor/servers.json`
- Historical metrics: `~/Library/Application Support/ServerMonitor/history/`
- iCloud sync: `NSUbiquitousKeyValueStore` (key-value store, not CloudKit)
