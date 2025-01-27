package main

import (
	"backend/pkg/api"
	"backend/pkg/serialhandler"
	"flag"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"

	"github.com/gorilla/mux"
)

func main() {
	// Parse the config path from command-line arguments
	configPath := flag.String("config", "", "Path to the configuration file")
	flag.Parse()

	// Default to the server's directory if no path is provided
	if *configPath == "" {
		executablePath, err := os.Executable()
		if err != nil {
			log.Fatalf("Failed to get executable path: %v", err)
		}
		executableDir := filepath.Dir(executablePath)
		*configPath = filepath.Join(executableDir, "config.json")
	}

	// Load the config
	config, err := serialhandler.LoadConfig(*configPath)
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize serial port
	var port *serialhandler.Port
	port, err = serialhandler.NewPort(*config)
	if err != nil {
		log.Printf("Failed to initialize serial port: %v", err)
	} else {
		defer port.Close()
		log.Println("Serial port initialized successfully.")
	}

	// Set up Router
	router := mux.NewRouter()
	api.SetupRoutes(router, port) // Pass the (potentially nil) port to the API

	// Run startup commands if the serial port is open
	if port != nil {
		log.Println("Running startup commands...")
		port.RunStartupCommands(config.StartupCommands)
	} else {
		log.Println("Startup commands skipped because the serial port is not initialized.")
	}

	// Start the server
	portStr := strconv.Itoa(config.ServerPort) // Convert integer to string
	log.Println("Server is listening on port", portStr)
	if err := http.ListenAndServe(":"+portStr, router); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
