class WebSocketService {
  constructor() {
    this.socket = null;
    this.messageHandlers = [];
  }

  connect() {
    // Use the environment variable for WebSocket URL
    // Falls back to constructing the URL if env variable is not set
    const wsUrl = process.env.REACT_APP_WEBSOCKET_URL;
    
    console.log(`Connecting to WebSocket at: ${wsUrl}`);
    
    this.socket = new WebSocket(wsUrl);
    
    this.socket.onopen = () => {
      console.log('WebSocket connection established');
    };
    
    this.socket.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        console.log('Received message:', data);
        
        // Notify all registered handlers
        this.messageHandlers.forEach(handler => handler(data));
      } catch (error) {
        console.error('Error parsing WebSocket message:', error);
      }
    };
    
    this.socket.onclose = () => {
      console.log('WebSocket connection closed');
      // Attempt to reconnect after a delay
      setTimeout(() => this.connect(), 5000);
    };
    
    this.socket.onerror = (error) => {
      console.error('WebSocket error:', error);
    };
  }

  addMessageHandler(handler) {
    this.messageHandlers.push(handler);
    return () => {
      this.messageHandlers = this.messageHandlers.filter(h => h !== handler);
    };
  }

  disconnect() {
    if (this.socket) {
      this.socket.close();
    }
  }
}

// Create a singleton instance
const websocketService = new WebSocketService();
export default websocketService; 