//
//  ServerMonitorApp.swift
//  ServerMonitor
//
//  Created by Simon Chiu on 2026-01-21.
//

import SwiftUI

@main
struct ServerMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(appDelegate.monitorService)
        }
        .defaultSize(width: 800, height: 500)
        .commands {
            CommandGroup(after: .appSettings) {
                Button("Refresh All Servers") {
                    Task {
                        await appDelegate.monitorService.refreshAllServers()
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appDelegate.monitorService)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var monitorService = MonitorService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up menu bar if enabled
        if monitorService.showInMenuBar {
            setupMenuBar()
        }

        // Listen for menu bar visibility changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMenuBarVisibilityChanged),
            name: .menuBarVisibilityChanged,
            object: nil
        )

        // Start monitoring if autoStartOnLaunch is enabled
        if monitorService.autoStartOnLaunch {
            monitorService.startMonitoring()
        }
    }

    @objc private func handleMenuBarVisibilityChanged() {
        if monitorService.showInMenuBar {
            if statusItem == nil {
                setupMenuBar()
            }
        } else {
            removeMenuBar()
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "server.rack", accessibilityDescription: "Server Monitor")
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(monitorService)
        )
    }

    private func removeMenuBar() {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
        popover = nil
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
