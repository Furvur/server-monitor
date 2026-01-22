//
//  ServiceDefinitionTests.swift
//  ServerMonitorTests
//

import Testing
import Foundation
@testable import ServerMonitor

struct ServiceDefinitionTests {

    // MARK: - ServiceCategory Tests

    @Test func serviceCategoryDisplayNames() {
        #expect(ServiceCategory.container.displayName == "Containers")
        #expect(ServiceCategory.webServer.displayName == "Web Servers")
        #expect(ServiceCategory.database.displayName == "Databases")
        #expect(ServiceCategory.cache.displayName == "Cache & Queues")
        #expect(ServiceCategory.runtime.displayName == "Runtimes")
        #expect(ServiceCategory.system.displayName == "System")
        #expect(ServiceCategory.custom.displayName == "Custom")
    }

    @Test func serviceCategoryIcons() {
        #expect(ServiceCategory.container.icon == "shippingbox")
        #expect(ServiceCategory.webServer.icon == "globe")
        #expect(ServiceCategory.database.icon == "cylinder")
        #expect(ServiceCategory.cache.icon == "bolt.horizontal")
        #expect(ServiceCategory.runtime.icon == "gearshape.2")
        #expect(ServiceCategory.system.icon == "wrench.and.screwdriver")
        #expect(ServiceCategory.custom.icon == "star")
    }

    @Test func serviceCategoryAllCases() {
        #expect(ServiceCategory.allCases.count == 7)
    }

    // MARK: - ServiceParseMode Tests

    @Test func serviceParseModeRawValues() {
        #expect(ServiceParseMode.activeInactive.rawValue == "activeInactive")
        #expect(ServiceParseMode.processCount.rawValue == "processCount")
        #expect(ServiceParseMode.dockerContainers.rawValue == "dockerContainers")
        #expect(ServiceParseMode.lineCount.rawValue == "lineCount")
        #expect(ServiceParseMode.exitCode.rawValue == "exitCode")
        #expect(ServiceParseMode.custom.rawValue == "custom")
    }

    // MARK: - ServiceDefinition Tests

    @Test func serviceDefinitionInitialization() {
        let service = ServiceDefinition(
            name: "Test Service",
            icon: "star",
            category: .custom,
            checkCommand: "echo test",
            parseMode: .custom
        )

        #expect(service.name == "Test Service")
        #expect(service.icon == "star")
        #expect(service.category == .custom)
        #expect(service.checkCommand == "echo test")
        #expect(service.parseMode == .custom)
        #expect(service.isBuiltIn == false)
    }

    @Test func serviceDefinitionCodable() throws {
        let original = ServiceDefinition(
            name: "Test",
            icon: "gear",
            category: .system,
            checkCommand: "systemctl status test",
            parseMode: .activeInactive,
            isBuiltIn: true
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ServiceDefinition.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.category == original.category)
        #expect(decoded.parseMode == original.parseMode)
    }
}

struct BuiltInServicesTests {

    // MARK: - Built-in Services Tests

    @Test func builtInServicesNotEmpty() {
        #expect(!BuiltInServices.all.isEmpty)
    }

    @Test func builtInServicesHaveUniqueIds() {
        let ids = BuiltInServices.all.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    @Test func builtInServicesAreMarkedAsBuiltIn() {
        for service in BuiltInServices.all {
            #expect(service.isBuiltIn == true)
        }
    }

    // MARK: - Service Lookup Tests

    @Test func serviceWithIdReturnsCorrectService() {
        let dockerId = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
        let docker = BuiltInServices.service(withId: dockerId)

        #expect(docker != nil)
        #expect(docker?.name == "Docker")
    }

    @Test func serviceWithIdReturnsNilForUnknownId() {
        let unknownId = UUID()
        let service = BuiltInServices.service(withId: unknownId)

        #expect(service == nil)
    }

    // MARK: - Category Grouping Tests

    @Test func byCategoryGroupsCorrectly() {
        let byCategory = BuiltInServices.byCategory

        #expect(byCategory[.container] != nil)
        #expect(byCategory[.webServer] != nil)
        #expect(byCategory[.database] != nil)
        #expect(byCategory[.cache] != nil)
        #expect(byCategory[.runtime] != nil)
        #expect(byCategory[.system] != nil)
    }

    @Test func containerServicesIncludeDocker() {
        let containers = BuiltInServices.byCategory[.container] ?? []
        let hasDocker = containers.contains { $0.name == "Docker" }

        #expect(hasDocker)
    }

    @Test func webServerServicesIncludeNginx() {
        let webServers = BuiltInServices.byCategory[.webServer] ?? []
        let hasNginx = webServers.contains { $0.name == "Nginx" }

        #expect(hasNginx)
    }

    @Test func databaseServicesIncludePostgreSQL() {
        let databases = BuiltInServices.byCategory[.database] ?? []
        let hasPostgres = databases.contains { $0.name == "PostgreSQL" }

        #expect(hasPostgres)
    }

    // MARK: - Common Services Tests

    @Test func commonServicesContainsExpectedServices() {
        let common = BuiltInServices.commonServices
        let names = common.map { $0.name }

        #expect(names.contains("Docker"))
        #expect(names.contains("Nginx"))
        #expect(names.contains("PostgreSQL"))
        #expect(names.contains("Redis"))
    }

    // MARK: - Auto-detect Command Tests

    @Test func autoDetectCommandIsNotEmpty() {
        #expect(!BuiltInServices.autoDetectCommand.isEmpty)
    }

    @Test func autoDetectCommandContainsServiceChecks() {
        let command = BuiltInServices.autoDetectCommand

        #expect(command.contains("docker"))
        #expect(command.contains("nginx"))
        #expect(command.contains("psql"))
        #expect(command.contains("redis-cli"))
    }

    @Test func autoDetectCommandUsesCommandV() {
        let command = BuiltInServices.autoDetectCommand

        #expect(command.contains("command -v"))
    }

    @Test func autoDetectCommandOutputsInstalledMarker() {
        let command = BuiltInServices.autoDetectCommand

        #expect(command.contains(":installed"))
    }
}
