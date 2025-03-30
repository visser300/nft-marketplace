package cron

import (
	"backend/models"
	"testing"
	"time"
)

func TestCronService(t *testing.T) {
	// Create a channel to receive events
	eventChan := make(chan models.Event)

	// Create and start the cron service
	service := NewCronService(eventChan)
	service.Start()

	// Wait for at least one event
	select {
	case event := <-eventChan:
		// Verify the event has the expected format
		if event.Event != "cron_tick" {
			t.Errorf("Expected event type 'cron_tick', got '%s'", event.Event)
		}

		// Try to parse the timestamp to ensure it's valid
		_, err := time.Parse(time.RFC3339, event.Message)
		if err != nil {
			t.Errorf("Invalid timestamp format: %v", err)
		}

	case <-time.After(2 * time.Second):
		t.Error("Timed out waiting for cron event")
	}

	// Stop the service
	service.Stop()
}
