package api

import (
	"backend/pkg/serialhandler"

	"github.com/gorilla/mux"
)

func SetupRoutes(router *mux.Router, port *serialhandler.Port) {
	handlers := &Handlers{Port: port}
	router.HandleFunc("/api/button/{id}", handlers.HandleButtonClick).Methods("POST")
	router.HandleFunc("/api/checkMeetingStatus", handlers.GetCurrentMeetingStatusFromEnv).Methods("GET")
}
