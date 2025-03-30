package cron

import (
	"backend/evm"
	"backend/models"
	"encoding/json"
	"log"
	"os"
	"strconv"
	"time"
)

// Service handles the cron jobs
type Service struct {
	eventChan chan models.Event
	stopChan  chan struct{}
}

// NewCronService creates a new cron service
func NewCronService(eventChan chan models.Event) *Service {
	return &Service{
		eventChan: eventChan,
		stopChan:  make(chan struct{}),
	}
}

// EventsData represents the combined transfer and approval events
type EventsData struct {
	TransferEvents []evm.TransferEvent `json:"transferEvents"`
	ApprovalEvents []evm.ApprovalEvent `json:"approvalEvents"`
	Timestamp      string              `json:"timestamp"`
}

// Start begins the cron service
func (s *Service) Start() {
	contract := os.Getenv("CONTRACT_ADDRESS")
	fromBlock := os.Getenv("FROM_BLOCK")
	toBlock := os.Getenv("TO_BLOCK")

	log.Println("Starting cron service...")
	ticker := time.NewTicker(1 * time.Second)

	go func() {
		for {
			select {
			case <-ticker.C:
				// Collect events from ScanMultipleContracts
				transferEvents, approvalEvents, err := evm.ScanMultipleContracts([]string{contract}, fromBlock, toBlock)
				if err != nil {
					log.Printf("Error scanning events: %v", err)
				}

				// Update block range for next scan
				fromBlock = toBlock
				fromBlockInt, _ := strconv.Atoi(fromBlock)
				toBlock = strconv.Itoa(fromBlockInt + 1000)

				// Create event data structure
				eventsData := EventsData{
					TransferEvents: transferEvents,
					ApprovalEvents: approvalEvents,
					Timestamp:      time.Now().Format(time.RFC3339),
				}

				// Convert to JSON
				jsonData, err := json.Marshal(eventsData)
				if err != nil {
					log.Printf("Error marshaling events to JSON: %v", err)
					jsonData = []byte("{}")
				}

				// Send event with JSON data
				s.eventChan <- models.Event{
					Event:   "cron_tick",
					Message: string(jsonData),
				}
			case <-s.stopChan:
				ticker.Stop()
				return
			}
		}
	}()
}

// Stop halts the cron service
func (s *Service) Stop() {
	close(s.stopChan)
}
