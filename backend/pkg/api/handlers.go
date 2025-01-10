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
	// Make sure the TV is on //
	wolMessage := sendWakeOnLan(h)
	w.Write([]byte(fmt.Sprintf("Wake on LAN: %s\n", wolMessage)))

	// Continue button handler logic
	vars := mux.Vars(r)
	buttonID, err := strconv.Atoi(vars["id"]) // Convert ID to integer
	if err != nil {
		http.Error(w, "Invalid button ID", http.StatusBadRequest)
		return
	}

	commandKey := fmt.Sprintf("input_%d", buttonID-1) // -1 because offsets on default inputs since turn off / on is reserved for the 0 and 1 IDs
	command := h.Port.Config.LabeledCommands[commandKey]
	if buttonID == 0 {
		command = h.Port.Config.LabeledCommands["turn_off"]
	}
	if buttonID == 1 {
		command = h.Port.Config.LabeledCommands["turn_on"]
	}

	if err := h.Port.Write(command); err != nil {
		http.Error(w, "Failed to send command", http.StatusInternalServerError)
		return
	}
	w.Write([]byte(fmt.Sprintf("Sent command: %s", command)))
}
