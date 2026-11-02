// Command search runs one Google search with the PacketStream Search API and prints the results.
package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"
)

const apiURL = "https://api.packetstream.io/v1/search"

type searchRequest struct {
	Query   string `json:"query"`
	Type    string `json:"type,omitempty"`
	Country string `json:"country,omitempty"`
}

type searchResponse struct {
	ResultCount int `json:"result_count"`
	// ai_mode returns its answer in an ai_mode block and has no results list
	Results []struct {
		Position int    `json:"position"`
		Title    string `json:"title"`
		URL      string `json:"url"`
		// autocomplete items carry a suggestion instead of a title and URL
		Suggestion string `json:"suggestion"`
	} `json:"results"`
	Error *struct {
		Code    string `json:"code"`
		Message string `json:"message"`
	} `json:"error"`
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run() error {
	apiKey := os.Getenv("PACKETSTREAM_API_KEY")
	if apiKey == "" {
		return errors.New("set PACKETSTREAM_API_KEY")
	}

	// Only query is required. Leave out type and country to use the defaults: search and us.
	body := searchRequest{
		Query:   strings.Join(os.Args[1:], " "),
		Type:    os.Getenv("PACKETSTREAM_SEARCH_TYPE"),
		Country: os.Getenv("PACKETSTREAM_SEARCH_COUNTRY"),
	}
	if body.Query == "" {
		body.Query = "residential proxy"
	}
	fmt.Printf("Search: type=%s country=%s query=%q\n", or(body.Type, "search"), or(body.Country, "us"), body.Query)

	encoded, err := json.Marshal(body)
	if err != nil {
		return err
	}
	req, err := http.NewRequestWithContext(context.Background(), http.MethodPost, apiURL, bytes.NewReader(encoded))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Content-Type", "application/json")

	// The server finishes or gives up within 25 seconds, so wait a little longer
	client := &http.Client{Timeout: 40 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	var payload searchResponse
	decodeErr := json.NewDecoder(resp.Body).Decode(&payload)
	if resp.StatusCode != http.StatusOK {
		if decodeErr == nil && payload.Error != nil {
			return fmt.Errorf("error %d: %s: %s", resp.StatusCode, payload.Error.Code, payload.Error.Message)
		}
		return fmt.Errorf("error %d: unexpected response", resp.StatusCode)
	}
	if decodeErr != nil {
		return fmt.Errorf("decode response: %w", decodeErr)
	}

	fmt.Printf("Results: %d\n", payload.ResultCount)
	for _, result := range payload.Results {
		title := or(result.Title, result.Suggestion)
		fmt.Println(strings.TrimRight(fmt.Sprintf("%d. %s  %s", result.Position, title, result.URL), " "))
	}
	return nil
}

func or(value, fallback string) string {
	if value == "" {
		return fallback
	}
	return value
}
