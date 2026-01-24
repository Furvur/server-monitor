VERSION := 1.0.0
LDFLAGS := -ldflags "-X main.Version=$(VERSION) -s -w"
BINARY_NAME := server-monitor-agent

.PHONY: all build build-linux-amd64 build-linux-arm64 clean test

all: build

build: build-linux-amd64 build-linux-arm64

build-linux-amd64:
	@echo "Building for linux/amd64..."
	GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o dist/$(BINARY_NAME)-linux-amd64 ./cmd/server-monitor-agent

build-linux-arm64:
	@echo "Building for linux/arm64..."
	GOOS=linux GOARCH=arm64 go build $(LDFLAGS) -o dist/$(BINARY_NAME)-linux-arm64 ./cmd/server-monitor-agent

build-darwin-arm64:
	@echo "Building for darwin/arm64 (for testing)..."
	GOOS=darwin GOARCH=arm64 go build $(LDFLAGS) -o dist/$(BINARY_NAME)-darwin-arm64 ./cmd/server-monitor-agent

test:
	go test -v ./...

clean:
	rm -rf dist/

# Install systemd service (run on target server)
install:
	@echo "Installing agent..."
	mkdir -p /var/lib/server-monitor /var/log/server-monitor
	cp dist/$(BINARY_NAME)-linux-$$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/') /usr/local/bin/$(BINARY_NAME)
	chmod +x /usr/local/bin/$(BINARY_NAME)
	@echo "Creating systemd service..."
	@echo '[Unit]' > /etc/systemd/system/server-monitor-agent.service
	@echo 'Description=Server Monitor Agent' >> /etc/systemd/system/server-monitor-agent.service
	@echo 'After=network.target' >> /etc/systemd/system/server-monitor-agent.service
	@echo '' >> /etc/systemd/system/server-monitor-agent.service
	@echo '[Service]' >> /etc/systemd/system/server-monitor-agent.service
	@echo 'Type=simple' >> /etc/systemd/system/server-monitor-agent.service
	@echo 'ExecStart=/usr/local/bin/$(BINARY_NAME) --interval 60' >> /etc/systemd/system/server-monitor-agent.service
	@echo 'Restart=always' >> /etc/systemd/system/server-monitor-agent.service
	@echo 'RestartSec=10' >> /etc/systemd/system/server-monitor-agent.service
	@echo '' >> /etc/systemd/system/server-monitor-agent.service
	@echo '[Install]' >> /etc/systemd/system/server-monitor-agent.service
	@echo 'WantedBy=multi-user.target' >> /etc/systemd/system/server-monitor-agent.service
	systemctl daemon-reload
	systemctl enable server-monitor-agent
	systemctl start server-monitor-agent
	@echo "Agent installed and started!"

uninstall:
	@echo "Uninstalling agent..."
	-systemctl stop server-monitor-agent
	-systemctl disable server-monitor-agent
	rm -f /etc/systemd/system/server-monitor-agent.service
	rm -f /usr/local/bin/$(BINARY_NAME)
	rm -rf /var/lib/server-monitor
	rm -rf /var/log/server-monitor
	systemctl daemon-reload
	@echo "Agent uninstalled!"
