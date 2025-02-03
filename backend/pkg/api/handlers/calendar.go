package handlers

import (
	"backend/internal/calendar"
	"backend/pkg/utils"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"time"

	"github.com/joho/godotenv"
)

type Time struct {
	DateTime string `json:"dateTime"`
	TimeZone string `json:"timeZone"`
}

type Event struct {
	Subject string `json:"subject"`
	Start   Time   `json:"start"`
	End     Time   `json:"end"`
}

type EventsResponse struct {
	Value []Event `json:"value"`
}

// Define the response struct for a single room
type RoomAvailabilityResponse struct {
	RoomEmail        string                     `json:"roomEmail"`
	RoomAvailability *calendar.RoomAvailability `json:"roomAvailability"`
	Error            string                     `json:"error,omitempty"`
}

func loadEnv() error {
	return godotenv.Load()
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
	accessToken, err := utils.GetAccessToken(clientID, clientSecret, tenantID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to get access token: %v", err), http.StatusInternalServerError)
		return
	}

	// Define the time range for availability check
	now := time.Now()
	startTime := time.Date(now.Year(), now.Month(), now.Day(), 1, 0, 0, 0, now.Location()) // 01:00 AM today
	endTime := time.Date(now.Year(), now.Month(), now.Day(), 23, 0, 0, 0, now.Location())  // 11:00 PM today

	// List of meeting room email addresses
	roomEmail := "mr-gamma@vestergaardcompany.com"

	// Initialize the response struct
	var roomResponse RoomAvailabilityResponse

	availability, err := calendar.CheckRoomAvailability(roomEmail, accessToken, startTime, endTime)
	if err != nil {
		// Return an error in the response JSON
		roomResponse = RoomAvailabilityResponse{
			RoomEmail: roomEmail,
			Error:     err.Error(),
		}
	} else {
		// Return the room's availability
		roomResponse = RoomAvailabilityResponse{
			RoomEmail:        roomEmail,
			RoomAvailability: availability,
		}
	}

	// Write the aggregated response as JSON
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(roomResponse); err != nil {
		http.Error(w, fmt.Sprintf("Failed to encode response: %v", err), http.StatusInternalServerError)
		return
	}
}

func getCurrentMeetingStatus(accessToken string) (*EventsResponse, error) {
	mail := "mr-gamma@vestergaardcompany.com"
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
