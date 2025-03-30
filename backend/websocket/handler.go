package websocket

import (
	"backend/models"
	"encoding/json"
	"log"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins for testing
	},
}

// Hub maintains the set of active clients and broadcasts messages to them
type Hub struct {
	clients    map[*Client]bool
	register   chan *Client
	unregister chan *Client
	eventChan  chan models.Event
	mutex      sync.Mutex
}

// Client represents a connected websocket client
type Client struct {
	hub  *Hub
	conn *websocket.Conn
	send chan []byte
}

// NewHub creates a new hub with the given event channel
func NewHub(eventChan chan models.Event) *Hub {
	return &Hub{
		clients:    make(map[*Client]bool),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		eventChan:  eventChan,
	}
}

// Run starts the hub
func (h *Hub) Run() {
	go func() {
		for {
			select {
			case client := <-h.register:
				h.mutex.Lock()
				h.clients[client] = true
				h.mutex.Unlock()
				log.Println("New client connected")
			case client := <-h.unregister:
				h.mutex.Lock()
				if _, ok := h.clients[client]; ok {
					delete(h.clients, client)
					close(client.send)
				}
				h.mutex.Unlock()
				log.Println("Client disconnected")
			case event := <-h.eventChan:
				h.broadcastEvent(event)
			}
		}
	}()
}

// broadcastEvent sends an event to all connected clients
func (h *Hub) broadcastEvent(event models.Event) {
	data, err := json.Marshal(event)
	if err != nil {
		log.Printf("Error marshaling event: %v", err)
		return
	}

	h.mutex.Lock()
	for client := range h.clients {
		select {
		case client.send <- data:
		default:
			close(client.send)
			delete(h.clients, client)
		}
	}
	h.mutex.Unlock()
}

// ServeWs handles websocket requests from clients
func (h *Hub) ServeWs(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return
	}

	client := &Client{
		hub:  h,
		conn: conn,
		send: make(chan []byte, 256),
	}
	client.hub.register <- client

	// Start goroutines for reading and writing
	go client.writePump()
}

// writePump pumps messages from the hub to the websocket connection
func (c *Client) writePump() {
	defer func() {
		c.conn.Close()
		c.hub.unregister <- c
	}()

	for {
		select {
		case message, ok := <-c.send:
			if !ok {
				// The hub closed the channel
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			if err := w.Close(); err != nil {
				return
			}
		}
	}
}
