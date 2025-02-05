package serialhandler

import (
	"encoding/json"
	"io/ioutil"
	"os"
)

// Config holds all configuration options for your application.
type Config struct {
	Device           string            `json:"device"`
	BaudRate         int               `json:"baud_rate"`
	DataBits         int               `json:"data_bits"`
	StopBits         int               `json:"stop_bits"`
	Parity           string            `json:"parity"`
	LabeledCommands  map[string]string `json:"labeled_commands"`
	StartupCommands  []string          `json:"startup_commands"`
	TVBroadcastIP    string            `json:"tv_broadcast_ip"`
	TVMacAddress     string            `json:"tv_macaddress"`
	ServerPort       int               `json:"server_port"`
	MeetingRoomEmail string            `json:"meeting_room_email"`
}

// AppConfig is a package-level variable that will hold your application's configuration.
// Other packages can access this variable by importing the serialhandler package.
var AppConfig *Config

// LoadConfig reads the configuration file at the given path, parses it, and assigns it
// to the AppConfig global variable.
func LoadConfig(filePath string) (*Config, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	data, err := ioutil.ReadAll(file)
	if err != nil {
		return nil, err
	}

	var config Config
	err = json.Unmarshal(data, &config)
	if err != nil {
		return nil, err
	}

	// Set the global configuration variable
	AppConfig = &config

	return &config, nil
}
