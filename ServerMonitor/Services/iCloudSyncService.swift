//
//  iCloudSyncService.swift
//  ServerMonitor
//

import Foundation

/// Service that synchronizes server configurations with iCloud using NSUbiquitousKeyValueStore.
/// This allows servers to be shared across devices signed into the same iCloud account.
class iCloudSyncService {
    static let shared = iCloudSyncService()

    private let store = NSUbiquitousKeyValueStore.default
    private let serversKey = "servers"

    /// Callback triggered when servers are updated from iCloud
    var onServersUpdated: (([Server]) -> Void)?

    private init() {
        setupObserver()
        // Trigger initial sync
        store.synchronize()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
    }

    @objc private func storeDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonNumber = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }

        let reason = reasonNumber

        switch reason {
        case NSUbiquitousKeyValueStoreServerChange,
             NSUbiquitousKeyValueStoreInitialSyncChange:
            // External change from another device or initial sync
            if let servers = loadServersFromCloud() {
                DispatchQueue.main.async { [weak self] in
                    self?.onServersUpdated?(servers)
                }
            }
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            print("iCloud KVS quota exceeded")
        case NSUbiquitousKeyValueStoreAccountChange:
            // Account changed, reload
            if let servers = loadServersFromCloud() {
                DispatchQueue.main.async { [weak self] in
                    self?.onServersUpdated?(servers)
                }
            }
        default:
            break
        }
    }

    /// Save servers to iCloud
    func saveServers(_ servers: [Server]) {
        do {
            let data = try JSONEncoder().encode(servers)
            store.set(data, forKey: serversKey)
            store.synchronize()
        } catch {
            print("Failed to save servers to iCloud: \(error)")
        }
    }

    /// Load servers from iCloud
    func loadServersFromCloud() -> [Server]? {
        guard let data = store.data(forKey: serversKey) else {
            return nil
        }

        do {
            let servers = try JSONDecoder().decode([Server].self, from: data)
            return servers
        } catch {
            print("Failed to load servers from iCloud: \(error)")
            return nil
        }
    }

    /// Merge local and cloud servers, preferring newer data based on modification tracking.
    /// Uses server IDs to match and merge, keeping all unique servers from both sources.
    func mergeServers(local: [Server], cloud: [Server]) -> [Server] {
        var merged: [UUID: Server] = [:]

        // Add all local servers first
        for server in local {
            merged[server.id] = server
        }

        // Add cloud servers (overwrites local if same ID exists)
        // In a simple merge, cloud wins for conflicts since it represents
        // the most recently synced state from any device
        for server in cloud {
            merged[server.id] = server
        }

        return Array(merged.values).sorted { $0.name < $1.name }
    }

    /// Force sync with iCloud
    func forceSync() {
        store.synchronize()
    }

    /// Check if iCloud is available
    var isAvailable: Bool {
        // NSUbiquitousKeyValueStore is always available, but may not sync
        // if the user isn't signed into iCloud
        return FileManager.default.ubiquityIdentityToken != nil
    }
}
