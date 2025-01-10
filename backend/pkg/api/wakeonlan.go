package api

import (
	"log"

	"github.com/linde12/gowol"
)

func sendWakeOnLan(h *Handlers) string {
	ipBroadcast := h.Port.Config.TVBroadcastIP
	macAddress := h.Port.Config.TVMacAddress

	packet, err := gowol.NewMagicPacket(macAddress)
	if err != nil {
		log.Println("Error creating magic packet:", err)
		log.Println("MACAddress:", macAddress)
		return "Error creating magic packet"
	}
	if err := packet.Send(ipBroadcast); err != nil {
		log.Println("Error sending magic packet to broadcast:", err)
		return "Error sending magic packet to broadcast"
	}
	log.Println("Sent Wake on Lan Signal!")
	return "Sent Wake on Lan Signal"
}
