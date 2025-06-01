# Trae Rules for `adapters` Directory

## 1. Functionality

The `adapters` directory is responsible for bridging the SDK with native platform functionalities or third-party libraries. It contains specific implementations for various concerns like network monitoring, preference management, and potentially filesystem access or logging mechanisms.

- **Network Adapters (e.g., `NetworkURLSessionAdapter.swift`)**: Intercept and monitor network traffic. They typically use platform-specific APIs (like `URLProtocol` on iOS) to capture request and response data, which is then formatted and sent to the ConsoleBus backend via utility functions (e.g., `NetworkUtil`).
- **Preference Adapters (e.g., `PreferenceAdapter.swift`, `PreferenceUserDefaultsAdapter.swift`)**: Manage application preferences. They provide an abstraction layer for accessing and modifying stored preferences (like `UserDefaults` on iOS). Changes and current values are reported to the ConsoleBus backend.
- **Other Adapters (e.g., `filesystem/`, `log/`)**: These subdirectories are placeholders for potential future adapters related to filesystem operations or custom logging integrations.

## 2. Directory Structure

The `adapters` directory is organized by the type of functionality they adapt:

```
adapters/
├── network/                  # Adapters for network operations
│   └── NetworkURLSessionAdapter.swift
├── perference/               # Adapters for preference management
│   ├── PreferenceAdapter.swift
│   └── PreferenceUserDefaultsAdapter.swift
├── filesystem/               # (Placeholder) Adapters for filesystem interactions
├── log/                      # (Placeholder) Adapters for logging mechanisms
└── trae_rules.md             # This file
```

## 3. Coding Standards

- **Naming Conventions**:
    - Swift files and class names should follow Swift naming conventions (e.g., `UpperCamelCase` for types, `lowerCamelCase` for methods and properties).
    - Adapter classes should clearly indicate their purpose (e.g., `NetworkURLSessionAdapter`, `PreferenceUserDefaultsAdapter`).
- **Abstraction**:
    - Where applicable, define a base abstract class or protocol (e.g., `PreferenceAdapter`) to allow for different implementations.
- **Registration/Unregistration**: Adapters that hook into system functionalities (like `URLProtocol`) should provide static `register()` and `unregister()` methods.
- **Singleton Pattern**: For adapters that manage a global resource or state, a singleton pattern might be appropriate (e.g., `PreferenceAdapter.currentPreferenceAdapter`).
- **Error Handling**: Implement robust error handling, especially for network and filesystem operations.
- **Thread Safety**: Ensure thread safety, particularly for adapters that operate in multi-threaded environments (e.g., `NetworkURLSessionAdapter` uses an `OperationQueue`).
- **Dependencies**: Adapters should clearly define their dependencies, typically on utility classes (e.g., `NetworkUtil`, `PreferenceUtil`) for communication with the core SDK.

## 4. Internal and External Dependencies

### Internal Dependencies:
- **`utils` directory**: Adapters rely heavily on utility classes within the `utils` directory (e.g., `NetworkUtil`, `PreferenceUtil`, `DeviceUtil`) to format and send data to the ConsoleBus backend.
- **`protocols` directory**: Adapters may interact with data structures defined in the `protocols` directory if they directly construct or handle protocol messages (though often this is delegated to `utils`).
- **`ConsoleBusIOSSDK`**: Adapters might need access to the main SDK instance (e.g., `ConsoleBusIOSSDK.activeSDKInstance`) to get a `MessageConnector` for sending data.

### External Dependencies:
- **Foundation**: For basic Swift functionalities, data types, and networking (e.g., `URLProtocol`, `URLSession`, `UserDefaults`).

## 5. State Management

- **Adapter-Specific State**: Some adapters might manage their own internal state (e.g., `NetworkURLSessionAdapter` uses a unique ID for requests and an `OperationQueue`).
- **Global State Access**: Adapters like `PreferenceUserDefaultsAdapter` interact with global state (e.g., `UserDefaults`).
- **Communication of State**: Adapters are primarily responsible for observing platform state or events and communicating relevant information to the ConsoleBus backend. They generally do not hold significant application state themselves but rather report on it.