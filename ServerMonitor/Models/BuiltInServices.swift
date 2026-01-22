//
//  BuiltInServices.swift
//  ServerMonitor
//

import Foundation

struct BuiltInServices {
    /// All built-in service definitions
    static let all: [ServiceDefinition] = [
        // MARK: - Containers
        ServiceDefinition(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
            name: "Docker",
            icon: "shippingbox.fill",
            category: .container,
            checkCommand: "docker ps -a --format '{{.Names}}\t{{.State}}\t{{.Image}}\t{{.Status}}'",
            parseMode: .dockerContainers,
            isBuiltIn: true
        ),
        ServiceDefinition(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
            name: "Podman",
            icon: "shippingbox",
            category: .container,
            checkCommand: "podman ps -a --format '{{.Names}}\t{{.State}}\t{{.Image}}\t{{.Status}}'",
            parseMode: .dockerContainers,
            isBuiltIn: true
        ),

        // MARK: - Web Servers
        ServiceDefinition(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
            name: "Nginx",
            icon: "globe",
            category: .webServer,
            checkCommand: "systemctl is-active nginx 2>/dev/null || service nginx status >/dev/null 2>&1 && echo active",
            parseMode: .activeInactive,
            isBuiltIn: true
        ),
        ServiceDefinition(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000002")!,
            name: "Apache",
            icon: "globe",
            category: .webServer,
            checkCommand: "systemctl is-active apache2 2>/dev/null || systemctl is-active httpd 2>/dev/null",
            parseMode: .activeInactive,
            isBuiltIn: true
        ),
        ServiceDefinition(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000003")!,
            name: "Caddy",
            icon: "lock.shield",
            category: .webServer,
            checkCommand: "systemctl is-active caddy 2>/dev/null",
            parseMode: .activeInactive,
            isBuiltIn: true
        ),

        // MARK: - Databases
        ServiceDefinition(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
            name: "PostgreSQL",
            icon: "cylinder.fill",
            category: .database,
            checkCommand: "systemctl is-active postgresql 2>/dev/null || pg_isready >/dev/null 2>&1 && echo active",
            parseMode: .activeInactive,
            isBuiltIn: true
        ),
        ServiceDefinition(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!,
            name: "MySQL",
            icon: "cylinder.fill",
            category: .database,
            checkCommand: "systemctl is-active mysql 2>/dev/null || systemctl is-active mariadb 2>/dev/null",
            parseMode: .activeInactive,
            isBuiltIn: true
        ),
        ServiceDefinition(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000003")!,
            name: "MongoDB",
            icon: "leaf.fill",
            category: .database,
            checkCommand: "systemctl is-active mongod 2>/dev/null",
            parseMode: .activeInactive,
            isBuiltIn: true
        ),
        ServiceDefinition(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000004")!,
            name: "SQLite",
            icon: "cylinder",
            category: .database,
            checkCommand: "which sqlite3 >/dev/null 2>&1 && echo active",
            parseMode: .activeInactive,
            isBuiltIn: true
        ),

        // MARK: - Cache & Queues
        ServiceDefinition(
            id: UUID(uuidString: "40000000-0000-0000-0000-000000000001")!,
            name: "Redis",
            icon: "bolt.horizontal.fill",
            category: .cache,
            checkCommand: "systemctl is-active redis 2>/dev/null || systemctl is-active redis-server 2>/dev/null || redis-cli ping 2>/dev/null | grep -q PONG && echo active",
            parseMode: .activeInactive,
            isBuiltIn: true
        ),
        ServiceDefinition(
            id: UUID(uuidString: "40000000-0000-0000-0000-000000000002")!,
            name: "Memcached",
            icon: "memorychip",
            category: .cache,
            checkCommand: "systemctl is-active memcached 2>/dev/null",
            parseMode: .activeInactive,
            isBuiltIn: true
        ),
        ServiceDefinition(
            id: UUID(uuidString: "40000000-0000-0000-0000-000000000003")!,
            name: "RabbitMQ",
            icon: "arrow.left.arrow.right",
            category: .cache,
            checkCommand: "systemctl is-active rabbitmq-server 2>/dev/null",
            parseMode: .activeInactive,
            isBuiltIn: true
        ),
        ServiceDefinition(
            id: UUID(uuidString: "40000000-0000-0000-0000-000000000004")!,
            name: "Sidekiq",
            icon: "gearshape.2.fill",
            category: .cache,
            checkCommand: "pgrep -c sidekiq 2>/dev/null || echo 0",
            parseMode: .processCount,
            isBuiltIn: true
        ),

        // MARK: - Runtimes
        ServiceDefinition(
            id: UUID(uuidString: "50000000-0000-0000-0000-000000000001")!,
            name: "PM2 (Node)",
            icon: "terminal.fill",
            category: .runtime,
            checkCommand: "pm2 jlist 2>/dev/null | jq 'length' 2>/dev/null || echo 0",
            parseMode: .processCount,
            isBuiltIn: true
        ),
        ServiceDefinition(
            id: UUID(uuidString: "50000000-0000-0000-0000-000000000002")!,
            name: "Puma",
            icon: "hare.fill",
            category: .runtime,
            checkCommand: "pgrep -c puma 2>/dev/null || echo 0",
            parseMode: .processCount,
            isBuiltIn: true
        ),
        ServiceDefinition(
            id: UUID(uuidString: "50000000-0000-0000-0000-000000000003")!,
            name: "Unicorn",
            icon: "hare",
            category: .runtime,
            checkCommand: "pgrep -c unicorn 2>/dev/null || echo 0",
            parseMode: .processCount,
            isBuiltIn: true
        ),
        ServiceDefinition(
            id: UUID(uuidString: "50000000-0000-0000-0000-000000000004")!,
            name: "Gunicorn",
            icon: "terminal",
            category: .runtime,
            checkCommand: "pgrep -c gunicorn 2>/dev/null || echo 0",
            parseMode: .processCount,
            isBuiltIn: true
        ),

        // MARK: - System
        ServiceDefinition(
            id: UUID(uuidString: "60000000-0000-0000-0000-000000000001")!,
            name: "SSH",
            icon: "lock.fill",
            category: .system,
            checkCommand: "pgrep -x sshd >/dev/null 2>&1 && echo active || (systemctl is-active sshd 2>/dev/null || systemctl is-active ssh 2>/dev/null)",
            parseMode: .activeInactive,
            isBuiltIn: true
        ),
        ServiceDefinition(
            id: UUID(uuidString: "60000000-0000-0000-0000-000000000002")!,
            name: "Cron",
            icon: "clock.fill",
            category: .system,
            checkCommand: "pgrep -x cron >/dev/null 2>&1 && echo active || pgrep -x crond >/dev/null 2>&1 && echo active || (systemctl is-active cron 2>/dev/null || systemctl is-active crond 2>/dev/null)",
            parseMode: .activeInactive,
            isBuiltIn: true
        ),
        ServiceDefinition(
            id: UUID(uuidString: "60000000-0000-0000-0000-000000000003")!,
            name: "UFW Firewall",
            icon: "flame.fill",
            category: .system,
            checkCommand: "ufw status 2>/dev/null | grep -q 'Status: active' && echo active || echo inactive",
            parseMode: .activeInactive,
            isBuiltIn: true
        ),
        ServiceDefinition(
            id: UUID(uuidString: "60000000-0000-0000-0000-000000000004")!,
            name: "Fail2ban",
            icon: "shield.fill",
            category: .system,
            checkCommand: "systemctl is-active fail2ban 2>/dev/null",
            parseMode: .activeInactive,
            isBuiltIn: true
        ),
    ]

    /// Get services grouped by category
    static var byCategory: [ServiceCategory: [ServiceDefinition]] {
        Dictionary(grouping: all, by: { $0.category })
    }

    /// Common services for quick setup (most likely to be used)
    static var commonServices: [ServiceDefinition] {
        all.filter { service in
            ["Docker", "Nginx", "PostgreSQL", "Redis"].contains(service.name)
        }
    }

    /// Get a service by ID
    static func service(withId id: UUID) -> ServiceDefinition? {
        all.first { $0.id == id }
    }

    /// Auto-detect command - returns IDs of services that appear to be installed
    static var autoDetectCommand: String {
        """
        echo "===SERVICES==="
        command -v docker >/dev/null 2>&1 && echo "docker:installed"
        command -v podman >/dev/null 2>&1 && echo "podman:installed"
        command -v nginx >/dev/null 2>&1 && echo "nginx:installed"
        command -v apache2 >/dev/null 2>&1 && echo "apache:installed"
        command -v httpd >/dev/null 2>&1 && echo "apache:installed"
        command -v caddy >/dev/null 2>&1 && echo "caddy:installed"
        command -v psql >/dev/null 2>&1 && echo "postgresql:installed"
        command -v mysql >/dev/null 2>&1 && echo "mysql:installed"
        command -v mongod >/dev/null 2>&1 && echo "mongodb:installed"
        command -v redis-cli >/dev/null 2>&1 && echo "redis:installed"
        command -v memcached >/dev/null 2>&1 && echo "memcached:installed"
        command -v rabbitmqctl >/dev/null 2>&1 && echo "rabbitmq:installed"
        command -v sidekiq >/dev/null 2>&1 && echo "sidekiq:installed"
        command -v pm2 >/dev/null 2>&1 && echo "pm2:installed"
        command -v puma >/dev/null 2>&1 && echo "puma:installed"
        command -v gunicorn >/dev/null 2>&1 && echo "gunicorn:installed"
        """
    }
}
