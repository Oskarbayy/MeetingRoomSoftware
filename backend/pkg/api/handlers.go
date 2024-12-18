package api

import (
	"backend/pkg/serialhandler"
	"fmt"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
)

type Handlers struct {
	Port *serialhandler.Port
}

func (h *Handlers) HandleButtonClick(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	buttonID, err := strconv.Atoi(vars["id"]) // Convert ID to integer
	if err != nil {
		http.Error(w, "Invalid button ID", http.StatusBadRequest)
		return
	}

	commandKey := fmt.Sprintf("input_%d", buttonID)
	command := h.Port.Config.LabeledCommands[commandKey]
	if buttonID == 0 {
		command = h.Port.Config.LabeledCommands["turn_off"]
	}
	if err := h.Port.Write(command); err != nil {
		http.Error(w, "Failed to send command", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(fmt.Sprintf("Sent command: %s", command)))
}
