# Trae Rules for `utils` Directory

## 1. Functionality

The `utils` directory contains helper classes and static methods that provide various utility functions for the SDK. These utilities are generally stateless and offer reusable logic for common tasks such as device information retrieval, log formatting and sending, network event construction, preference handling, and local file management.

- **`DeviceUtil.swift`**: Provides static methods to get device-specific information:
    - `getDeviceName()`: Returns the device name and model.
    - `getDeviceType()`: Returns the device type (e.g., "iOS").
    - `getDeviceId()`: Returns a unique identifier for the device (vendor UUID).

- **`LocalFileManager.swift`**: Manages local log files.
    - `LocalFileManagerConfig`: A configuration class to specify `maxDaysToKeep`, `maxFolderSizeMB`, and `batchDeleteCount` for log cleaning.
    - `cleanLogFiles(config:)`: A static method to clean up old or excessive log files in the `console-bus-log` cache directory based on the provided configuration (age and size).

- **`LogUtil.swift`**: Handles logging functionality.
    - `LogLevel` (enum): Defines log levels (`debug`, `info`, `warn`, `error`) with associated priorities.
    - `LogMessageBuilder` (typealias): A closure type for building log messages lazily.
    - `captureScreenWhenError` (static var): A flag to enable/disable screen capture on error logs.
    - `minimumLogLevel` (static var): Sets the minimum log level to be processed.
    - `setMinimumLogLevel(_:)`: Sets the minimum log level.
    - `processLogContent(_:)`: Converts various message types (String, UIImage, other) into a string representation and content type (text, image, object).
    - `log(tag:level:messageBuilder:)`: The core private logging function that creates a `ProtoConsole` message and sends it via the active `MessageConnector`.
    - Public static methods for each log level (`debug`, `info`, `warn`, `error`) that call the internal `log` method.
    - Includes an extension on `UIView` for `consolebus_snapshot()` to capture a view's snapshot.

- **`NetworkUtil.swift`**: Constructs and sends network activity messages (`ProtoNetwork`).
    - `requestMap` (static var): A dictionary to temporarily store ongoing requests to correlate them with responses/errors.
    - `getRequestBody(from:)`: Extracts the request body as a string.
    - `onNetworkRequest(uniqueId:request:)`: Called when a network request starts. Creates and sends a `ProtoNetwork` message with request details.
    - `onNetworkResponse(uniqueId:response:data:)`: Called when a network response is received. Creates and sends an updated `ProtoNetwork` message with response details.
    - `onNetworkCancel(uniqueId:request:)`: Called when a request is cancelled.
    - `onNetworkError(uniqueId:request:error:)`: Called when a network request fails.
    - All `onNetwork*` methods create a `ProtoNetwork` message and send it via the active `MessageConnector`.

- **`PreferenceUtil.swift`**: Handles preference-related messages.
    - `getValueType(_:)`: Determines the string representation of a value's type (e.g., "string", "number", "map").
    - `onGetKeyValue(key:value:)`: Called when a preference key-value pair is retrieved. Creates a `ProtoPreference` message (operation "get") and sends it via the active `MessageConnector`.

## 2. Directory Structure

```
utils/
├── DeviceUtil.swift          # Utilities for device information
├── LocalFileManager.swift    # Utilities for managing local log files
├── LogUtil.swift             # Utilities for logging
├── NetworkUtil.swift         # Utilities for network monitoring
├── PreferenceUtil.swift      # Utilities for preference handling
└── trae_rules.md             # This file
```

## 3. Coding Standards

- **Naming Conventions**:
    - Swift files and class names follow Swift naming conventions (e.g., `UpperCamelCase` for types, `lowerCamelCase` for methods and properties).
    - Utility class names end with `Util` (e.g., `DeviceUtil`, `LogUtil`).
- **Statelessness**: Utility methods should ideally be static and stateless, operating only on their input parameters.
- **Static Methods**: Most utility functions are provided as static methods on the utility class.
- **Clarity and Reusability**: Functions should be well-documented and designed for reusability across different parts of the SDK.
- **Error Handling**: Utility functions that can fail (e.g., file operations) should handle errors gracefully, often by printing to the console or having minimal impact.
- **Dependencies**: Utilities often depend on `Proto*` classes to construct messages and the active `MessageConnector` (obtained via `ConsoleBusIOSSDK.activeSDKInstance?.connector`) to send them.
- **Private Helpers**: Internal logic should be encapsulated in private static methods where appropriate.

## 4. Internal and External Dependencies

### Internal Dependencies:
- **`protocols` directory**: All utility classes that send data (e.g., `LogUtil`, `NetworkUtil`, `PreferenceUtil`) depend on the `Proto*` classes (e.g., `ProtoConsole`, `ProtoNetwork`, `ProtoPreference`) to create message objects.
- **`connectors` directory**: Specifically, they need access to an active `MessageConnector` instance to send the serialized protocol messages. This is typically retrieved via `ConsoleBusIOSSDK.activeSDKInstance?.connector`.
- **`ConsoleBusIOSSDK`**: For accessing the `activeSDKInstance` to get the connector.
- `DeviceUtil` is used by other `Util` classes and `ConsoleBusIOSSDK` to get device identifiers.

### External Dependencies:
- **Foundation**: For basic Swift data types, `UUID`, `Date`, `JSONSerialization`, `FileManager`, `URLRequest`, `URLResponse`, etc.
- **UIKit** (for `DeviceUtil`, `LogUtil`):
    - `DeviceUtil`: Uses `UIDevice` and `utsname` (via `uname`) for device information.
    - `LogUtil`: Uses `UIImage`, `UIApplication`, `UIWindowScene`, `UIView` for screen capture functionality.

## 5. State Management

- **Generally Stateless**: Most utility classes and their methods are stateless. They perform operations based on input parameters and do not maintain internal state across calls, with a few exceptions:
    - **`LogUtil.minimumLogLevel` and `LogUtil.captureScreenWhenError`**: These are static variables that configure the logging behavior globally.
    - **`NetworkUtil.requestMap`**: This static dictionary holds temporary state about ongoing network requests to correlate them with responses or errors. This state is short-lived, corresponding to the duration of a network request.
- Utilities primarily act as data processors and message constructors, relying on other components (like connectors) for stateful operations like maintaining connections or persistent storage.