package models

// Event represents a message sent to clients via WebSocket
type Event struct {
	Event   string `json:"event"`
	Message string `json:"message"`
}
