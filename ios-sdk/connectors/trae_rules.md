# Trae Rules for `connectors` Directory

## 1. Functionality

The `connectors` directory is responsible for managing the communication channels between the SDK and the ConsoleBus backend or local storage. It abstracts the underlying transport mechanisms (like WebSockets or local file I/O) and provides a consistent interface for sending and receiving messages.

- **`MessageConnector.swift`**: This is an abstract base class that defines the common interface for all connectors. It includes:
    - A message buffer (`messageBuffer`) to temporarily store messages if the connection is unavailable or if sending fails.
    - A maximum buffer size (`maxBufferSize`).
    - An error handling callback (`onError`).
    - Abstract methods `send(message: String)` and `stop()` that must be implemented by subclasses.
    - Helper methods for managing the buffer (`addToBuffer`, `clearBuffer`, `getSortedMessages`, `handleBufferLimit`).

- **`WebSocketConnector.swift`**: This class implements `MessageConnector` for real-time communication over WebSockets.
    - Manages WebSocket connection lifecycle (`connect`, `disconnect`).
    - Handles automatic reconnection with an exponential backoff strategy (`scheduleReconnect`, `reconnectAttempt`, `maxReconnectDelay`).
    - Sends messages via the WebSocket connection and buffers them if disconnected.
    - Receives messages from the WebSocket and triggers the `onMessage` callback.
    - Provides callbacks for connection events (`onConnect`, `onDisconnect`).
    - Implements `URLSessionWebSocketDelegate` to handle WebSocket events.

- **`LocalFileConnector.swift`**: This class implements `MessageConnector` for persisting messages to local files.
    - Writes messages to a `.cblog` file in the application's cache directory (`console-bus-log`).
    - Generates a timestamped filename or uses a provided filename.
    - Uses a `DispatchQueue` for asynchronous file operations.
    - Implements a timed flush mechanism (`flushInterval`, `flushTimer`) to periodically write buffered messages to disk.
    - Flushes the buffer if it exceeds `maxBufferSize` or when the connector is stopped.

## 2. Directory Structure

```
connectors/
├── LocalFileConnector.swift    # Connector for writing messages to local files
├── MessageConnector.swift      # Abstract base class for message connectors
├── WebSocketConnector.swift    # Connector for WebSocket communication
└── trae_rules.md               # This file
```

## 3. Coding Standards

- **Naming Conventions**:
    - Swift files and class names follow Swift naming conventions (e.g., `UpperCamelCase` for types, `lowerCamelCase` for methods and properties).
    - Connector classes clearly indicate their transport mechanism (e.g., `WebSocketConnector`, `LocalFileConnector`).
- **Abstraction**: The `MessageConnector` base class provides a clear abstraction for sending messages, allowing different transport mechanisms to be used interchangeably by the SDK.
- **Error Handling**: Connectors should implement robust error handling and provide an `onError` callback for the SDK to be notified of issues.
- **Buffering**: Implement message buffering to handle temporary disconnections or failures, ensuring data is not lost.
- **Asynchronous Operations**: Network and file I/O operations should be performed asynchronously to avoid blocking the main thread (e.g., `WebSocketConnector` uses `URLSession`'s asynchronous methods, `LocalFileConnector` uses a `DispatchQueue`).
- **Lifecycle Management**: Connectors should have clear `start` (or `connect`) and `stop` (or `disconnect`) methods to manage their lifecycle.
- **Reconnection Logic (for network connectors)**: Implement robust reconnection strategies (e.g., exponential backoff) for network-based connectors like `WebSocketConnector`.
- **Configuration**: Allow configuration of parameters like buffer size, host/port, filenames, etc.

## 4. Internal and External Dependencies

### Internal Dependencies:
- None directly, but these classes are instantiated and used by `ConsoleBusIOSSDK.swift`.

### External Dependencies:
- **Foundation**: For basic Swift functionalities, networking (`URLSession`, `URLSessionWebSocketTask`), file I/O (`FileManager`, `FileHandle`), timers (`Timer`), and dispatch queues (`DispatchQueue`).

## 5. State Management

- **Connection State (`WebSocketConnector`)**: Manages the state of the WebSocket connection (`isConnected`, `shouldReconnect`).
- **Message Buffer (`MessageConnector` and subclasses)**: All connectors maintain a buffer of messages (`messageBuffer`) along with timestamps.
- **Reconnect State (`WebSocketConnector`)**: Manages reconnection attempts and timers (`reconnectTimer`, `reconnectAttempt`).
- **File Handles/Paths (`LocalFileConnector`)**: Manages the URL and potentially file handles for the log file.

Connectors are primarily responsible for managing the state of the communication channel and the buffer of messages waiting to be transmitted or processed. They report errors and connection status changes via callbacks.