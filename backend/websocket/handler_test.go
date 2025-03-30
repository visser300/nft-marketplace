package websocket

import (
	"backend/models"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gorilla/websocket"
)

func TestWebSocketConnection(t *testing.T) {
	// Create event channel and hub
	eventChan := make(chan models.Event)
	hub := NewHub(eventChan)
	hub.Run()

	// Create test server
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		hub.ServeWs(w, r)
	}))
	defer server.Close()

	// Convert http URL to ws URL
	url := "ws" + strings.TrimPrefix(server.URL, "http") + "/ws"

	// Connect to WebSocket server
	ws, _, err := websocket.DefaultDialer.Dial(url, nil)
	if err != nil {
		t.Fatalf("Could not connect to WebSocket server: %v", err)
	}
	defer ws.Close()

	// Send an event through the channel
	testEvent := models.Event{
		Event:   "test_event",
		Message: "test message",
	}

	// Use a goroutine to send the event
	go func() {
		// Wait a bit to ensure connection is established
		time.Sleep(100 * time.Millisecond)
		eventChan <- testEvent
	}()

	// Read the response
	_, message, err := ws.ReadMessage()
	if err != nil {
		t.Fatalf("Failed to read message: %v", err)
	}

	// Parse the response
	var receivedEvent models.Event
	if err := json.Unmarshal(message, &receivedEvent); err != nil {
		t.Fatalf("Failed to unmarshal message: %v", err)
	}

	// Verify the event
	if receivedEvent.Event != testEvent.Event || receivedEvent.Message != testEvent.Message {
		t.Errorf("Expected event %+v, got %+v", testEvent, receivedEvent)
	}
}
