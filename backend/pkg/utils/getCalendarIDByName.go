package utils

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
)

func GetCalendarIDByName(userEmail, accessToken, calendarName string) (string, error) {
	url := fmt.Sprintf("https://graph.microsoft.com/v1.0/users/%s/calendars", userEmail)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", accessToken))
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := ioutil.ReadAll(resp.Body)
		return "", fmt.Errorf("failed to fetch calendars: %s, response: %s", resp.Status, string(body))
	}

	var calendarResp struct {
		Value []struct {
			Id   string `json:"id"`
			Name string `json:"name"`
		} `json:"value"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&calendarResp); err != nil {
		return "", fmt.Errorf("failed to decode response: %w", err)
	}

	for _, calendar := range calendarResp.Value {
		if calendar.Name == calendarName {
			return calendar.Id, nil
		}
	}

	return "", fmt.Errorf("calendar with name '%s' not found", calendarName)
}
