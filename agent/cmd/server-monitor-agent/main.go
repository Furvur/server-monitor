package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/furvur/server-monitor-agent/internal/collector"
	"github.com/furvur/server-monitor-agent/internal/output"
	"github.com/furvur/server-monitor-agent/internal/service"
	"github.com/furvur/server-monitor-agent/pkg/models"
)

// Version is set at build time via ldflags
var Version = "dev"

func main() {
	// Parse command line flags
	interval := flag.Int("interval", 60, "Collection interval in seconds")
	outputPath := flag.String("output", output.DefaultOutputPath, "Output file path")
	once := flag.Bool("once", false, "Run once and exit (for testing)")
	version := flag.Bool("version", false, "Print version and exit")
	flag.Parse()

	if *version {
		fmt.Println("server-monitor-agent version", Version)
		os.Exit(0)
	}

	log.Printf("Server Monitor Agent %s starting", Version)
	log.Printf("Collection interval: %d seconds", *interval)
	log.Printf("Output path: %s", *outputPath)

	// Create collector and writer
	coll := collector.New(Version)
	writer := output.NewWriter(*outputPath)

	// Run once if requested
	if *once {
		if err := collectAndWrite(coll, writer); err != nil {
			log.Fatalf("Collection failed: %v", err)
		}
		log.Println("Collection complete")
		return
	}

	// Set up signal handling for graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Initial collection
	if err := collectAndWrite(coll, writer); err != nil {
		log.Printf("Initial collection failed: %v", err)
	}

	// Start collection loop
	ticker := time.NewTicker(time.Duration(*interval) * time.Second)
	defer ticker.Stop()

	log.Println("Agent running. Press Ctrl+C to stop.")

	for {
		select {
		case <-ticker.C:
			if err := collectAndWrite(coll, writer); err != nil {
				log.Printf("Collection failed: %v", err)
			}
		case sig := <-sigChan:
			log.Printf("Received signal %v, shutting down", sig)
			return
		}
	}
}

func collectAndWrite(coll *collector.Collector, writer *output.Writer) error {
	// Collect base metrics
	metrics := coll.Collect()

	// Collect service statuses
	var services []models.ServiceStatus

	// Check Docker
	if dockerStatus, installed := service.CheckDocker(); installed {
		services = append(services, dockerStatus)
	}

	// Check common systemd services
	services = append(services, service.CheckCommonServices()...)

	metrics.Services = services

	// Write to file
	if err := writer.Write(metrics); err != nil {
		return fmt.Errorf("failed to write metrics: %w", err)
	}

	log.Printf("Metrics collected: load=%.2f mem=%dMB/%dMB disk=%.1f%%",
		metrics.Load.Load1,
		metrics.Memory.UsedMB, metrics.Memory.TotalMB,
		metrics.Disk.UsagePercent)

	return nil
}
