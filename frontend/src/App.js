import React, { useState, useEffect } from 'react';
import websocketService from './services/websocket';
import './App.css';

function App() {
  const [messages, setMessages] = useState([]);
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    // Connect to WebSocket when component mounts
    websocketService.connect();
    setConnected(true);

    // Register message handler
    const removeHandler = websocketService.addMessageHandler((data) => {
      setMessages(prevMessages => [...prevMessages, data]);
    });

    // Cleanup on component unmount
    return () => {
      removeHandler();
      websocketService.disconnect();
    };
  }, []);

  return (
    <div className="app-container">
      <header className="app-header">
        <h1>WebSocket Client</h1>
        <div className={`connection-status ${connected ? 'connected' : 'disconnected'}`}>
          {connected ? 'Connected' : 'Disconnected'}
        </div>
      </header>

      <div className="message-container">
        <h2>Messages</h2>
        {messages.length === 0 ? (
          <p className="no-messages">No messages received yet...</p>
        ) : (
          <ul className="message-list">
            {messages.map((message, index) => (
              <li key={index} className="message-item">
                <pre>{JSON.stringify(message, null, 2)}</pre>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}

export default App; 