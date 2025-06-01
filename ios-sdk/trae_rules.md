# Trae Rules for `ios-sdk` Root Directory

## 1. Functionality

The root directory of the `ios-sdk` project contains the primary entry point and core orchestration logic for the ConsoleBus iOS SDK. It is responsible for initializing the SDK, managing its lifecycle, configuring communication channels, and coordinating interactions between different modules (adapters, connectors, protocols, utils).

- **`ConsoleBusIOSSDK.swift`**: This is the main public class for the SDK.
    - **Initialization**: Takes a `ConnectorConfig` (which can be `WebSocketConnectorConfig` or `LocalFileConnectorConfig`) to determine how the SDK communicates.
    - **Lifecycle Management**: Provides `start()` and `stop()` methods to activate and deactivate the SDK's functionalities. It maintains a static reference to the `activeSDKInstance`.
    - **Connector Setup**: Based on the provided configuration, it instantiates and configures the appropriate `MessageConnector` (`WebSocketConnector` or `LocalFileConnector`).
    - **Core Operations on Start**:
        - Sends device information (`ProtoDevice`) upon successful connection or initialization.
        - Synchronizes preferences by calling `getAll()` on the `PreferenceAdapter.currentPreferenceAdapter`.
    - **Message Handling** (for `WebSocketConnector`):
        - Listens for incoming messages.
        - Uses `ProtocolMessageFactory` to parse messages.
        - Filters out messages not intended for the current device.
        - Handles incoming `ProtoPreference` messages with "set" operation by calling `setValue` on the `PreferenceAdapter`.
        - Handles incoming `ProtoPreference` messages with "sync" operation by re-triggering preference synchronization.
    - **Configuration Classes**:
        - `ConnectorConfig`: Base class for connector configurations.
        - `WebSocketConnectorConfig`: Holds `host` and `port` for WebSocket connections.
        - `LocalFileConnectorConfig`: Holds an optional `filename` for local file logging.

- **`ios_sdk.h`**: This is the umbrella header file for the framework, making Swift classes and methods visible to Objective-C if the SDK is used in a mixed-language project. It also defines the framework's version number and string.

## 2. Directory Structure

```
ios-sdk/
├── adapters/                   # Platform-specific adapters
├── connectors/                 # Communication channel connectors
├── onboard/                    # Onboarding/initial setup (currently empty)
├── protocols/                  # Data structures for communication
├── utils/                      # Utility functions
├── consolebus-ios-sdk.swift    # Main SDK class and configuration
├── ios_sdk.h                   # Framework umbrella header
└── trae_rules.md               # This file
```

## 3. Coding Standards

- **Public API Design**: The `ConsoleBusIOSSDK` class provides a clear and concise public API for integrating applications.
- **Singleton Pattern**: Uses a static variable `activeSDKInstance` to provide global access to the active SDK instance, though it's managed and set during the `start()` method.
- **Configuration-driven**: The SDK's behavior, particularly its communication method, is determined by the `ConnectorConfig` object passed during initialization.
- **Modularity**: Delegates specific tasks to other modules (e.g., message sending to `MessageConnector`, preference storage to `PreferenceAdapter`, device info to `DeviceUtil`).
- **Error Handling**: Implicitly relies on connectors and adapters for their specific error handling. WebSocket connection errors are handled by the `WebSocketConnector`'s reconnection logic.
- **Asynchronous Operations**: Uses closures for callbacks (e.g., `onConnect`, `onMessage` for `WebSocketConnector`) and `DispatchQueue.main.async` for UI-related or main-thread-dependent initializations with `LocalFileConnector`.
- **Type Safety**: Uses type casting (`as?`) to determine the specific type of `ConnectorConfig` and to parse incoming messages.

## 4. Internal and External Dependencies

### Internal Dependencies:
- **`connectors` directory**: `MessageConnector`, `WebSocketConnector`, `LocalFileConnector`.
- **`protocols` directory**: `ProtoDevice`, `ProtoPreference`, `ProtocolMessageFactory`.
- **`utils` directory**: `DeviceUtil`.
- **`adapters` directory**: `PreferenceAdapter` (indirectly, via static access `PreferenceAdapter.currentPreferenceAdapter`).

### External Dependencies:
- **Foundation**: For `Date`, `UUID`, `JSONSerialization`, `Data`, basic Swift types.

## 5. State Management

- **`activeSDKInstance`**: A static, nullable reference to the currently active `ConsoleBusIOSSDK` instance. This represents the global state of whether the SDK is running and provides access to its components.
- **`connectorConfig`**: An instance variable holding the configuration for the communication channel. This state is set at initialization.
- **`connector`**: An instance variable holding the active `MessageConnector`. Its state (e.g., connection status for WebSocket) is managed by the connector itself.
- The SDK orchestrates state changes in other modules, for example, by triggering preference synchronization or updates based on incoming messages.