# Trae Rules for `protocols` Directory

## 1. Functionality

The `protocols` directory defines the data structures (message types) used for communication between the SDK and the ConsoleBus backend/frontend. Each file typically represents a specific type of message or a related group of messages.

- **`ProtoMessageBase.swift`**: This is the base class for all protocol messages. It defines common fields required in every message:
    - `deviceId`: A unique identifier for the device.
    - `msgId`: A unique identifier for the message itself.
    - `featureId`: A string identifying the feature this message relates to (e.g., "console", "network", "device", "preference").
    - `createdAt`: A timestamp (in milliseconds) indicating when the message was created.
    - It provides `toJson()` and `toJSONString()` methods for serializing the message to a JSON dictionary or string.

- **`ProtoConsole.swift`**: Defines the structure for console log messages.
    - Inherits from `ProtoMessageBase`.
    - Specific fields: `logTag`, `logContent`, `logContentType` (e.g., "text", "image", "object"), `logLevel` (e.g., "debug", "info", "warn", "error").
    - Includes a static `fromJSON()` method to deserialize a JSON dictionary into a `ProtoConsole` object.

- **`ProtoDevice.swift`**: Defines the structure for messages carrying device information.
    - Inherits from `ProtoMessageBase`.
    - Specific fields: `deviceName`, `deviceType`.
    - Includes a static `fromJSON()` method.

- **`ProtoNetwork.swift`**: Defines the structure for network request/response messages.
    - Inherits from `ProtoMessageBase`.
    - Specific fields: `uniqueId` (to link request and response), `requestUri`, `requestHeaders`, `requestMethod`, `requestBody`, `responseHeaders`, `responseStatusCode`, `responseBody`, `requestTime`, `responseTime`.
    - Includes a static `fromJSON()` method.

- **`ProtoPreference.swift`**: Defines the structure for messages related to application preferences.
    - Inherits from `ProtoMessageBase`.
    - Specific fields: `key` (preference key), `value` (preference value), `operation` (e.g., "set", "get", "sync"), `type` (data type of the value, e.g., "string", "number").
    - Includes a static `fromJSON()` method.

- **`ProtocolMessageFactory.swift`**: A factory class responsible for deserializing a generic JSON dictionary into a specific `ProtoMessageBase` subclass based on the `featureId` field.
    - Provides a static `fromJSON()` method that inspects the `featureId` and delegates to the appropriate `Proto*.fromJSON()` method.

## 2. Directory Structure

```
protocols/
├── ProtoConsole.swift          # Protocol for console log messages
├── ProtoDevice.swift           # Protocol for device information messages
├── ProtoMessageBase.swift      # Base class for all protocol messages
├── ProtoNetwork.swift          # Protocol for network activity messages
├── ProtoPreference.swift       # Protocol for preference messages
├── ProtocolMessageFactory.swift # Factory for creating protocol messages from JSON
└── trae_rules.md               # This file
```

## 3. Coding Standards

- **Naming Conventions**:
    - Swift files and class names follow Swift naming conventions (e.g., `UpperCamelCase` for types, `lowerCamelCase` for methods and properties).
    - Protocol class names are prefixed with `Proto` (e.g., `ProtoConsole`).
- **Immutability**: Message properties are generally declared as `let` (constants) as messages represent a snapshot of data at a point in time.
- **Serialization/Deserialization**:
    - Each protocol class (except the base) should provide a static `fromJSON(_ json: [String: Any]) -> Self?` method for deserialization.
    - The `ProtoMessageBase` class provides `toJson() -> [String: Any]` and `toJSONString() -> String?` methods for serialization, which subclasses override to include their specific fields.
- **Base Class**: All specific protocol messages must inherit from `ProtoMessageBase`.
- **Error Handling in Deserialization**: `fromJSON` methods should return an optional (`Self?`) and handle potential missing or mismatched types in the input JSON by returning `nil`.
- **No Business Logic**: Protocol classes should primarily be data containers. They should not contain business logic beyond serialization and deserialization.
- **Clarity of Fields**: Field names should be descriptive and match the expected JSON structure.
- **`Codable`**: While `ProtoMessageBase` conforms to `Codable`, the current implementation uses custom `toJson()` and `fromJSON()` methods. The `required init(from decoder: Decoder)` is typically a `fatalError` as custom parsing is preferred for flexibility with `Any` types (like in `ProtoPreference.value`).

## 4. Internal and External Dependencies

### Internal Dependencies:
- These protocol classes are used throughout the SDK, particularly by:
    - **`utils` classes** (e.g., `LogUtil`, `NetworkUtil`, `PreferenceUtil`) which create instances of these protocol messages.
    - **`connectors`** which send the serialized string representation of these messages.
    - **`ConsoleBusIOSSDK.swift`** which might use `ProtocolMessageFactory` to parse incoming messages.

### External Dependencies:
- **Foundation**: For basic Swift data types, `JSONSerialization`, `Date`, etc.

## 5. State Management

- Protocol classes themselves are stateless data containers. They represent individual messages and do not manage or hold any ongoing state related to the application or communication channel. Their state is defined by their properties at the time of instantiation.