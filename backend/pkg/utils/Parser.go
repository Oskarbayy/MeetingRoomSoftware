package utils

import (
	"log"

	"go.bug.st/serial"
)

func ParseParity(parity string) serial.Parity {
	switch parity {
	case "none":
		return serial.NoParity
	case "even":
		return serial.EvenParity
	case "odd":
		return serial.OddParity
	default:
		return serial.NoParity // Default to no parity if invalid
	}
}

func ParseStopBits(stopBits int) serial.StopBits {
	switch stopBits {
	case 1:
		return serial.OneStopBit
	case 2:
		return serial.TwoStopBits
	default:
		log.Printf("Invalid stop bits value: %d. Defaulting to OneStopBit.", stopBits)
		return serial.OneStopBit
	}
}
