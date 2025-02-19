package handlers

import (
	"backend/internal/calendar"
	"backend/pkg/serialhandler"
	"backend/pkg/utils"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/joho/godotenv"
)

// Initialize a logger to write to serverlog.txt
var serverLogger *log.Logger

func init() {
	// Open or create the log file
	logFile, err := os.OpenFile("serverlog.txt", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0666)
	if err != nil {
		log.Fatalf("Failed to open log file: %v", err)
	}

	// Log to both file and console
	multiWriter := io.MultiWriter(os.Stdout, logFile)
	serverLogger = log.New(multiWriter, "SERVER: ", log.Ldate|log.Ltime|log.Lshortfile)
	serverLogger.Println("Logging started")
}

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

type RoomAvailabilityResponse struct {
	RoomEmail        string                     `json:"roomEmail"`
	RoomAvailability *calendar.RoomAvailability `json:"roomAvailability"`
	Error            string                     `json:"error,omitempty"`
}

func loadEnv() error {
	return godotenv.Load()
}

// Handler to get current meeting status and log the response
func (h *Handlers) GetCurrentMeetingStatusFromEnv(w http.ResponseWriter, r *http.Request) {
	serverLogger.Println("Received request for GetCurrentMeetingStatusFromEnv")

	// Load environment variables
	if err := loadEnv(); err != nil {
		serverLogger.Printf("Error loading .env file: %v", err)
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
		serverLogger.Printf("Failed to get access token: %v", err)
		http.Error(w, fmt.Sprintf("Failed to get access token: %v", err), http.StatusInternalServerError)
		return
	}
	serverLogger.Println("Access token retrieved successfully")

	// Define the time range for availability check
	now := time.Now()
	startTime := time.Date(now.Year(), now.Month(), now.Day(), 1, 0, 0, 0, now.Location()) // 01:00 AM today
	endTime := time.Date(now.Year(), now.Month(), now.Day(), 23, 0, 0, 0, now.Location())  // 11:00 PM today

	// List of meeting room email addresses
	roomEmail := serialhandler.AppConfig.MeetingRoomEmail

	// Initialize the response struct
	var roomResponse RoomAvailabilityResponse

	availability, err := calendar.CheckRoomAvailability(roomEmail, accessToken, startTime, endTime)
	if err != nil {
		serverLogger.Printf("Error checking room availability for %s: %v", roomEmail, err)
		roomResponse = RoomAvailabilityResponse{
			RoomEmail: roomEmail,
			Error:     err.Error(),
		}
	} else {
		serverLogger.Printf("Room availability for %s: %+v", roomEmail, availability)
		roomResponse = RoomAvailabilityResponse{
			RoomEmail:        roomEmail,
			RoomAvailability: availability,
		}
	}

	// Write the aggregated response as JSON
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(roomResponse); err != nil {
		serverLogger.Printf("Failed to encode response: %v", err)
		http.Error(w, fmt.Sprintf("Failed to encode response: %v", err), http.StatusInternalServerError)
		return
	}

	serverLogger.Println("Response successfully sent to client")
}

func getCurrentMeetingStatus(accessToken string) (*EventsResponse, error) {
	mail := serialhandler.AppConfig.MeetingRoomEmail
	url := fmt.Sprintf("https://graph.microsoft.com/v1.0/users/%s/events", mail)

	serverLogger.Printf("Fetching current meeting status from Graph API for %s", mail)

	// Create the HTTP GET request
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		serverLogger.Printf("Failed to create request: %v", err)
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", accessToken))
	req.Header.Set("Content-Type", "application/json")

	// Send the request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		serverLogger.Printf("Failed to send request: %v", err)
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	// Read and log the raw response body
	body, _ := ioutil.ReadAll(resp.Body)
	serverLogger.Printf("Raw response from Graph API: %s", string(body))

	// Check for a non-OK status code
	if resp.StatusCode != http.StatusOK {
		serverLogger.Printf("Failed to fetch events, status: %s", resp.Status)
		return nil, fmt.Errorf("failed to fetch events, status: %s, response: %s", resp.Status, string(body))
	}

	// Decode the JSON response into the EventsResponse struct
	var eventsResp EventsResponse
	if err := json.Unmarshal(body, &eventsResp); err != nil {
		serverLogger.Printf("Failed to decode response: %v", err)
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	// Log the decoded events
	serverLogger.Printf("Decoded Events: %+v", eventsResp)

	// Return the full EventsResponse struct
	return &eventsResp, nil
}
