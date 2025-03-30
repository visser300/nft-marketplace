# Backend Service

This is a Go backend service that provides:
1. A cron service that runs every second
2. A WebSocket stream that clients can connect to for receiving real-time events

## Prerequisites

- Go 1.21 or later

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd <repository-directory>/backend
   ```

2. Install dependencies:
   ```bash
   go mod download
   ```

## Running the Service

To start the backend service:

bash
go run main.go


The server will start on port 8080 with the following endpoints:
- `/ws` - WebSocket endpoint for real-time events
- `/health` - Health check endpoint

## Testing

Run the tests with:

bash
go test ./...

## WebSocket Events

The WebSocket stream sends events in the following JSON format:

json
{
"event": "event_type",
"message": "event message"
}

### Event Types

- `cron_tick`: Sent every second with the current timestamp
