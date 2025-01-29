package api

import (
	"backend/pkg/serialhandler"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
)

type Handlers struct {
	Port *serialhandler.Port
}

type TokenResponse struct {
	AccessToken string `json:"access_token"`
}

type Event struct {
	Subject string `json:"subject"`
	Start   Time   `json:"start"`
	End     Time   `json:"end"`
}

type Time struct {
	DateTime string `json:"dateTime"`
	TimeZone string `json:"timeZone"`
}

type EventsResponse struct {
	Value []Event `json:"value"`
}

func loadEnv() error {
	return godotenv.Load()
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

// Microsoft graph API
func getAccessToken(clientID, clientSecret, tenantID string) (string, error) {
	// Construct the OAuth2 token URL
	tokenURL := fmt.Sprintf("https://login.microsoftonline.com/%s/oauth2/v2.0/token", tenantID)

	// Use url.Values to create properly encoded form data
	formData := url.Values{
		"grant_type":    {"client_credentials"},
		"client_id":     {clientID},
		"client_secret": {clientSecret},
		"scope":         {"https://graph.microsoft.com/.default"},
	}

	// Create the HTTP POST request
	resp, err := http.Post(tokenURL, "application/x-www-form-urlencoded", strings.NewReader(formData.Encode()))
	if err != nil {
		return "", fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	// Check if the status code indicates success
	if resp.StatusCode != http.StatusOK {
		body, _ := ioutil.ReadAll(resp.Body)
		return "", fmt.Errorf("failed to get access token: %s, response: %s", resp.Status, string(body))
	}

	// Parse the response body for the access token
	var tokenResponse struct {
		AccessToken string `json:"access_token"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&tokenResponse); err != nil {
		return "", fmt.Errorf("failed to decode token response: %w", err)
	}

	return tokenResponse.AccessToken, nil
}

type RoomAvailability struct {
	IsAvailable bool     `json:"isAvailable"`
	BusyTimes   []string `json:"busyTimes"`
}

// CheckRoomAvailability checks if the meeting room is available
func CheckRoomAvailability(roomEmail, accessToken string, startTime, endTime time.Time) (*RoomAvailability, error) {
	// Format times using RFC3339 and ensure proper URL encoding
	startTimeStr := url.QueryEscape(startTime.Format("2006-01-02T15:04:05-07:00"))
	endTimeStr := url.QueryEscape(endTime.Format("2006-01-02T15:04:05-07:00"))

	// Log formatted and encoded times for debugging
	fmt.Printf("Formatted Start Time: %s\n", startTimeStr)
	fmt.Printf("Formatted End Time: %s\n", endTimeStr)

	// Microsoft Graph API endpoint
	url := fmt.Sprintf("https://graph.microsoft.com/v1.0/users/%s/calendarView?startDateTime=%s&endDateTime=%s",
		roomEmail, startTimeStr, endTimeStr)

	// Log the final URL
	fmt.Printf("Final URL: %s\n", url)

	// Create the HTTP GET request
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Set authorization headers
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", accessToken))
	req.Header.Set("Content-Type", "application/json")

	// Send the request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	// Handle non-200 status codes
	if resp.StatusCode != http.StatusOK {
		body, _ := ioutil.ReadAll(resp.Body)
		return nil, fmt.Errorf("failed to fetch calendar view: %s, response: %s", resp.Status, string(body))
	}

	// Parse the response
	var eventsResp struct {
		Value []struct {
			Start struct {
				DateTime string `json:"dateTime"`
			} `json:"start"`
			End struct {
				DateTime string `json:"dateTime"`
			} `json:"end"`
		} `json:"value"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&eventsResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	// Process events to determine availability
	var busyTimes []string
	for _, event := range eventsResp.Value {
		busyTimes = append(busyTimes, fmt.Sprintf("From: %s To: %s", event.Start.DateTime, event.End.DateTime))
	}

	return &RoomAvailability{
		IsAvailable: len(busyTimes) == 0,
		BusyTimes:   busyTimes,
	}, nil
}

func (h *Handlers) GetCurrentMeetingStatusFromEnv(w http.ResponseWriter, r *http.Request) {
	// Load environment variables
	if err := loadEnv(); err != nil {
		http.Error(w, fmt.Sprintf("Failed to load environment variables: %v", err), http.StatusInternalServerError)
		return
	}

	// Fetch required credentials from environment variables
	clientID := os.Getenv("CLIENT_ID")
	clientSecret := os.Getenv("CLIENT_SECRET")
	tenantID := os.Getenv("TENANT_ID")

	// Get access token
	accessToken, err := getAccessToken(clientID, clientSecret, tenantID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to get access token: %v", err), http.StatusInternalServerError)
		return
	}

	// Define the time range for availability check
	startTime := time.Now()
	endTime := startTime.Add(30 * time.Minute) // Next 30 minutes

	// List of meeting room email addresses
	roomEmails := []string{
		"mr-vts@vestergaardcompany.com",
		"mr-flexliner@vestergaardcompany.com",
		"mr-sws@vestergaardcompany.com",
		"mr-beta@vestergaardcompany.com",
		"mr-beta15@vestergaardcompany.com",
		"osha@vestergaardcompany.com",
	}

	// Prepare a slice to hold availability data for all rooms
	var roomAvailabilities []struct {
		RoomEmail    string            `json:"roomEmail"`
		Availability *RoomAvailability `json:"availability"`
		Error        string            `json:"error,omitempty"`
	}

	// Loop through each room and check availability
	for _, roomEmail := range roomEmails {
		availability, err := CheckRoomAvailability(roomEmail, accessToken, startTime, endTime)
		if err != nil {
			// Append the error for this room
			roomAvailabilities = append(roomAvailabilities, struct {
				RoomEmail    string            `json:"roomEmail"`
				Availability *RoomAvailability `json:"availability"`
				Error        string            `json:"error,omitempty"`
			}{
				RoomEmail: roomEmail,
				Error:     err.Error(),
			})
			continue
		}

		// Append the availability result for this room
		roomAvailabilities = append(roomAvailabilities, struct {
			RoomEmail    string            `json:"roomEmail"`
			Availability *RoomAvailability `json:"availability"`
			Error        string            `json:"error,omitempty"`
		}{
			RoomEmail:    roomEmail,
			Availability: availability,
		})
	}

	// Write the aggregated response as JSON
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(roomAvailabilities); err != nil {
		http.Error(w, fmt.Sprintf("Failed to encode response: %v", err), http.StatusInternalServerError)
		return
	}
}

func getCurrentMeetingStatus(accessToken string) (*EventsResponse, error) {
	mail := "mr-vts@vestergaardcompany.com"
	url := fmt.Sprintf("https://graph.microsoft.com/v1.0/users/%s/events", mail)

	// Create the HTTP GET request
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", accessToken))
	req.Header.Set("Content-Type", "application/json")

	// Send the request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	// Read and log the raw response body
	body, _ := ioutil.ReadAll(resp.Body)
	fmt.Printf("Raw response from Graph API: %s\n", string(body))

	// Check for a non-OK status code
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to fetch events, status: %s, response: %s", resp.Status, string(body))
	}

	// Decode the JSON response into the EventsResponse struct
	var eventsResp EventsResponse
	if err := json.Unmarshal(body, &eventsResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	// Log the decoded events
	fmt.Printf("Decoded Events: %+v\n", eventsResp)

	// Return the full EventsResponse struct
	return &eventsResp, nil
}
