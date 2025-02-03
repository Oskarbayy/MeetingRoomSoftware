package api

import (
	"backend/pkg/api/handlers"
	"backend/pkg/serialhandler"

	"github.com/gorilla/mux"
)

func SetupRoutes(router *mux.Router, port *serialhandler.Port) {
	h := &handlers.Handlers{Port: port}
	router.HandleFunc("/api/button/{id}", h.HandleButtonClick).Methods("POST")
	router.HandleFunc("/api/checkMeetingStatus", h.GetCurrentMeetingStatusFromEnv).Methods("GET")
}
