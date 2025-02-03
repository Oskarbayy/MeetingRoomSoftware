package calendar

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"strings"
	"time"
)

type RoomAvailability struct {
	IsAvailable bool   `json:"isAvailable"`
	FromTime    string `json:"FromTime"`
	ToTime      string `json:"ToTime"`
}

// CheckRoomAvailability checks if the meeting room is available
func CheckRoomAvailability(roomEmail, accessToken string, startTime, endTime time.Time) (*RoomAvailability, error) {
	// Format times using RFC3339 and ensure proper URL encoding
	startTimeStr := url.QueryEscape(startTime.Format("2006-01-02T15:04:05-07:00"))
	endTimeStr := url.QueryEscape(endTime.Format("2006-01-02T15:04:05-07:00"))

	// Microsoft Graph API endpoint
	url := fmt.Sprintf("https://graph.microsoft.com/v1.0/users/%s/calendarView?startDateTime=%s&endDateTime=%s",
		roomEmail, startTimeStr, endTimeStr)
	fmt.Println(url)

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
		fmt.Println("not ok status code error!")
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

	log.Printf("Number of events retrieved: %d\n", len(eventsResp.Value))

	// Determine the next relevant time (either when a meeting ends or starts)
	var startEventTime *time.Time
	var endEventTime *time.Time

	isCurrentlyBusy := false
	now := time.Now().UTC().Add(1 * time.Hour) // Adjust to UTC+1
	twoHoursLater := now.Add(2 * time.Hour)

	fmt.Println("Current Time (UTC+1):", now)
	fmt.Println("Checking for meetings within next 2 hours until:", twoHoursLater)

	for _, event := range eventsResp.Value {
		startTimeStr := event.Start.DateTime
		endTimeStr := event.End.DateTime

		if !strings.HasSuffix(startTimeStr, "Z") && !strings.Contains(startTimeStr, "+") {
			startTimeStr += "Z"
		}
		if !strings.HasSuffix(endTimeStr, "Z") && !strings.Contains(endTimeStr, "+") {
			endTimeStr += "Z"
		}

		eventStart, err := time.Parse(time.RFC3339Nano, startTimeStr)
		if err != nil {
			log.Printf("Failed to parse start time: %v, Raw Start: %s", err, startTimeStr)
			continue
		}

		eventEnd, err := time.Parse(time.RFC3339Nano, endTimeStr)
		if err != nil {
			log.Printf("Failed to parse end time: %v, Raw End: %s", err, endTimeStr)
			continue
		}

		// Convert to UTC+1
		eventStart = eventStart.UTC().Add(1 * time.Hour)
		eventEnd = eventEnd.UTC().Add(1 * time.Hour)

		log.Printf("Now (UTC+1): %v, Event Start (UTC+1): %v, Event End (UTC+1): %v\n", now, eventStart, eventEnd)

		// Check if the room is currently occupied
		if now.After(eventStart) && now.Before(eventEnd) {
			isCurrentlyBusy = true
			startEventTime = &eventStart // Meeting started at this time
			endEventTime = &eventEnd     // Meeting will end at this time
			log.Println("Room is currently occupied.")
			break // Stop checking as the room is already occupied
		}

		// Otherwise, find the next upcoming event within 2 hours
		if eventStart.After(now) && eventStart.Before(twoHoursLater) {
			if startEventTime == nil || eventStart.Before(*startEventTime) {
				startEventTime = &eventStart
			}
		}
	}

	var toTime string
	var fromTime string
	if isCurrentlyBusy {
		// If a meeting is happening now, set fromTime = meeting start and toTime = meeting end
		toTime = endEventTime.Format("2006-01-02T15:04:05-07:00")
		fromTime = startEventTime.Format("2006-01-02T15:04:05-07:00")
	} else if startEventTime != nil {
		// If no meeting is happening, but one is in 2 hours, start a countdown
		toTime = startEventTime.Format("2006-01-02T15:04:05-07:00")
		fromTime = now.Add(2 * time.Hour).Format("2006-01-02T15:04:05-07:00")
	} else {
		// No meeting within 2 hours
		log.Println("No upcoming events within the next 2 hours.")
	}

	log.Println("EMAIL:", roomEmail)
	log.Println("Next Event Time:", startEventTime)

	return &RoomAvailability{
		IsAvailable: !isCurrentlyBusy,
		FromTime:    fromTime,
		ToTime:      toTime,
	}, nil
}
