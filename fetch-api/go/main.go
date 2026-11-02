// Command fetch reads a web page as Markdown with the PacketStream Fetch API, following long pages.
package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"time"
)

const (
	apiURL = "https://api.packetstream.io/v1/fetch"
	// Each part is a separate fetch and is billed separately, so stop after a few.
	maxParts = 3
)

type fetchRequest struct {
	URL        string `json:"url"`
	MaxLength  int    `json:"max_length,omitempty"`
	StartIndex int    `json:"start_index,omitempty"`
}

type page struct {
	FinalURL       string `json:"final_url"`
	StatusCode     int    `json:"status_code"`
	Title          string `json:"title"`
	Content        string `json:"content"`
	StartIndex     int    `json:"start_index"`
	ReturnedLength int    `json:"returned_length"`
	TotalLength    int    `json:"total_length"`
	Truncated      bool   `json:"truncated"`
	NextStartIndex int    `json:"next_start_index"`
}

type fetchResponse struct {
	Page  *page `json:"page"`
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

	body := fetchRequest{URL: "https://example.com"}
	if len(os.Args) > 1 {
		body.URL = os.Args[1]
	}
	// Optional: a small max_length splits even a short page into parts
	if value := os.Getenv("PACKETSTREAM_FETCH_MAX_LENGTH"); value != "" {
		maxLength, err := strconv.Atoi(value)
		if err != nil || maxLength < 1 {
			return errors.New("PACKETSTREAM_FETCH_MAX_LENGTH must be a whole number")
		}
		body.MaxLength = maxLength
	}
	fmt.Println("Fetch: " + body.URL)

	// The server finishes or gives up within 25 seconds, so wait a little longer
	client := &http.Client{Timeout: 40 * time.Second}
	for part := 1; part <= maxParts; part++ {
		p, err := fetchPart(client, apiKey, body)
		if err != nil {
			return err
		}
		if part == 1 {
			fmt.Println("Title: " + p.Title)
			fmt.Println("Final URL: " + p.FinalURL)
			fmt.Printf("Status: %d\n", p.StatusCode)
		}
		fmt.Printf("\n--- Part %d: characters %d to %d of %d ---\n\n",
			part, p.StartIndex, p.StartIndex+p.ReturnedLength, p.TotalLength)
		fmt.Println(p.Content)

		if !p.Truncated {
			return nil
		}
		// Send the same request again, starting where this part ended
		body.StartIndex = p.NextStartIndex
	}
	fmt.Printf("\nStopped after %d parts. Continue with start_index=%d.\n", maxParts, body.StartIndex)
	return nil
}

func fetchPart(client *http.Client, apiKey string, body fetchRequest) (*page, error) {
	encoded, err := json.Marshal(body)
	if err != nil {
		return nil, err
	}
	req, err := http.NewRequestWithContext(context.Background(), http.MethodPost, apiURL, bytes.NewReader(encoded))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	var payload fetchResponse
	decodeErr := json.NewDecoder(resp.Body).Decode(&payload)
	if resp.StatusCode != http.StatusOK {
		if decodeErr == nil && payload.Error != nil {
			return nil, fmt.Errorf("error %d: %s: %s", resp.StatusCode, payload.Error.Code, payload.Error.Message)
		}
		return nil, fmt.Errorf("error %d: unexpected response", resp.StatusCode)
	}
	if decodeErr != nil || payload.Page == nil {
		return nil, errors.New("unexpected response")
	}
	return payload.Page, nil
}
