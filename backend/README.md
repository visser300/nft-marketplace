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
   # This will download all dependencies and update go.sum
   go mod tidy
   ```

   If you encounter any issues, you can try installing the specific packages:
   ```bash
   go get github.com/gorilla/websocket
   go get github.com/robfig/cron/v3
   ```

## Running the Service

To start the backend service:

```bash
go run main.go
```

The server will start on port 8080 with the following endpoints:
- `/ws` - WebSocket endpoint for real-time events
- `/health` - Health check endpoint

## Testing

Run the tests with:

```bash
go test ./...
```

## WebSocket Events

The WebSocket stream sends events in the following JSON format:

```json
{
  "event": "event_type",
  "message": "event message"
}
```

### Event Types

- `cron_tick`: Sent every second with the current timestamp

## Connecting from Frontend

Example JavaScript code to connect to the WebSocket:

```javascript
const socket = new WebSocket('ws://localhost:8080/ws');

socket.onopen = () => {
  console.log('Connected to WebSocket server');
};

socket.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Received event:', data);
  // Handle the event based on data.event and data.message
};

socket.onclose = () => {
  console.log('Disconnected from WebSocket server');
};
```

## Project Structure

- `main.go` - Entry point for the application
- `cron/service.go` - Cron service implementation
- `websocket/handler.go` - WebSocket handling
- `models/event.go` - Data models

## Troubleshooting

### Missing Dependencies

If you see errors like:
```
missing go.sum entry for module providing package github.com/gorilla/websocket
```

Run the following command to fix it:
```bash
go mod tidy
```

## Shutting Down

The service can be stopped with Ctrl+C (SIGINT) or SIGTERM signals.
