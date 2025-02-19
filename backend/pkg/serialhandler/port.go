package serialhandler

import (
	"backend/pkg/utils"
	"errors"
	"log"
	"strings"
	"time"

	"go.bug.st/serial"
)

type Port struct {
	serialPort serial.Port
	Config     Config
}

var selectedPort string

// NewPort opens the first available serial port containing "COM" instead of using config.Device (semi hardcoded name)
func NewPort(config Config) (*Port, error) {
	// List available serial ports
	ports, err := serial.GetPortsList()
	if err != nil {
		return nil, err
	}

	// Find a port containing "COM" (case-insensitive)

	for _, port := range ports {
		if strings.Contains(strings.ToLower(port), "com") {
			selectedPort = port
			break
		}
	}

	if selectedPort == "" {
		return nil, errors.New("no suitable COM port found")
	}

	log.Printf("Connecting to port: %s", selectedPort)

	// Configure serial connection
	mode := &serial.Mode{
		BaudRate: config.BaudRate,
		DataBits: config.DataBits,
		Parity:   utils.ParseParity(config.Parity),
		StopBits: utils.ParseStopBits(config.StopBits),
	}

	// Open the selected serial port
	sp, err := serial.Open(selectedPort, mode)
	if err != nil {
		return nil, err
	}

	log.Println("Serial port successfully opened")
	return &Port{serialPort: sp, Config: config}, nil
}

// Writes the command to the serial port
func (p *Port) Write(command string) error {
	_, err := p.serialPort.Write([]byte(command + "\r\n"))
	if err != nil {
		log.Printf("Failed to write to serial port: %v", err)
		return err
	}
	log.Printf("Command sent to %s: %s", selectedPort, command)

	//Wait for acknowledgment
	if p.WaitForAcknowledgment(5) != true { // Wait for up to 5 seconds
		log.Printf("No acknowledgment received for command: %s", command)
	}

	return nil
}

func (p *Port) Close() {
	p.serialPort.Close()
	log.Println("Serial port closed")
}

func (p *Port) RunStartupCommands(commands []string) {
	for _, command := range commands {
		err := p.Write(command)
		if err != nil {
			log.Printf("Failed to execute startup command: %s", command)
		} else {
			log.Printf("Startup command executed: %s", command)
		}
	}
}

func (p *Port) WaitForAcknowledgment(timeoutSeconds int) bool {
	startTime := time.Now()
	var messageBuffer string

	for {
		// Check if timeout has been reached
		if time.Since(startTime).Seconds() > float64(timeoutSeconds) {
			log.Printf("Acknowledgment timeout reached")
			return false
		}

		// Read data from the serial port
		buffer := make([]byte, 128)
		n, err := p.serialPort.Read(buffer)
		if err != nil {
			log.Printf("Error reading from serial port: %v", err)
			return false
		}

		if n > 0 {
			// Append received data to the buffer
			messageBuffer += string(buffer[:n])

			// Process complete messages
			for {
				// Find the index of the message delimiter (e.g., '\n')
				delimiterIndex := indexOfDelimiter(messageBuffer, "\n")

				// If no delimiter is found, wait for more data
				if delimiterIndex == -1 {
					break
				}

				// Extract the complete message and remove it from the buffer
				completeMessage := messageBuffer[:delimiterIndex]
				messageBuffer = messageBuffer[delimiterIndex+1:] // +1 to remove the delimiter

				// Log the complete message
				log.Printf("Received: %s", completeMessage)

				// Acknowledge the complete message
				return true
			}
		}

		// Sleep briefly to avoid tight looping
		time.Sleep(100 * time.Millisecond)
	}
}

// Helper function to find the index of a delimiter in a string
func indexOfDelimiter(data, delimiter string) int {
	for i := 0; i < len(data); i++ {
		if string(data[i]) == delimiter {
			return i
		}
	}
	return -1
}
