package main

import (
	"backend/pkg/api"
	"backend/pkg/serialhandler"
	"log"
	"net/http"

	"github.com/gorilla/mux"
)

func main() {
	config, err := serialhandler.LoadConfig("config.json")
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Open serial port
	port, err := serialhandler.NewPort(*config)
	if err != nil {
		log.Fatalf("Failed to initialize serial port: %v", err)
	}
	defer port.Close()

	// Set up Router
	router := mux.NewRouter()
	api.SetupRoutes(router, port)

	// Run startup commands
	log.Println("Running startup commands...")
	port.RunStartupCommands(config.StartupCommands)

	log.Println("Server is listening on port :8080...")
	if err := http.ListenAndServe(":8080", router); err != nil {
		log.Fatalf("Server failed: %v", err)
	}

}
