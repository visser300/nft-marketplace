package main

import (
	"backend/cron"
	"backend/models"
	"backend/websocket"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/joho/godotenv"
)

func main() {

	err := godotenv.Load()
	if err != nil {
		log.Println("Warning: .env file not found")
	}

	log.Println("Starting backend service...")

	// Create a channel for events
	eventChan := make(chan models.Event)

	// Initialize the WebSocket hub
	hub := websocket.NewHub(eventChan)
	hub.Run()

	// Initialize and start the cron service
	cronService := cron.NewCronService(eventChan)
	cronService.Start()

	// Set up HTTP routes
	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		hub.ServeWs(w, r)
	})

	// Add a simple health check endpoint
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// Start the HTTP server
	go func() {
		log.Println("HTTP server starting on :8080")
		if err := http.ListenAndServe(":8080", nil); err != nil {
			log.Fatalf("HTTP server error: %v", err)
		}
	}()

	// Wait for termination signal
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	log.Println("Shutting down...")
	cronService.Stop()
}
