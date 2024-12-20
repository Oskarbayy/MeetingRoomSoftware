package serialhandler

import (
	"encoding/json"
	"io/ioutil"
	"os"
)

type Config struct {
	Device          string            `json:"device"`
	BaudRate        int               `json:"baud_rate"`
	DataBits        int               `json:"data_bits"`
	StopBits        int               `json:"stop_bits"`
	Parity          string            `json:"parity"`
	LabeledCommands map[string]string `json:"labeled_commands"`
	StartupCommands []string          `json:"startup_commands"`
	ServerPort      int               `json:"server_port"`
}

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

	return &config, nil
}
