# Trae Rules for `onboard` Directory

## 1. Functionality

The `onboard` directory is intended to house functionalities related to the SDK's onboarding process. This could include:

- **Initial Configuration**: Code for setting up the SDK for the first time, such as collecting necessary permissions, initial user consent, or device registration with a backend service.
- **Guided Setup**: UI elements or logic to guide the developer or end-user through any necessary setup steps for the SDK to function correctly.
- **Feature Discovery/Enablement**: Mechanisms to inform the integrating application about available SDK features and allow for their selective enablement.
- **Welcome/Tutorial Flows**: If applicable, any introductory sequences for users of an application that leverages this SDK.

Currently, this directory is empty, indicating that onboarding functionalities are either handled elsewhere, are minimal, or are planned for future development.

## 2. Directory Structure

```
onboard/
└── trae_rules.md  # This file
```

As the directory is currently empty, its structure is minimal. Future additions would populate this directory with relevant Swift files, and potentially subdirectories if the onboarding logic becomes complex (e.g., `onboard/ui/`, `onboard/flows/`).

## 3. Coding Standards

If and when code is added to this directory, it should adhere to the general coding standards of the `ios-sdk` project, including:

- **Swift Best Practices**: Following Swift API Design Guidelines.
- **Naming Conventions**: `UpperCamelCase` for types, `lowerCamelCase` for methods and properties.
- **Modularity**: Onboarding steps should be broken down into manageable, reusable components or functions.
- **User Experience**: If UI elements are involved, they should be user-friendly and provide clear instructions.
- **Error Handling**: Robust error handling for any operations that might fail (e.g., network requests during registration, permission checks).
- **Asynchronous Operations**: Proper use of asynchronous patterns (e.g., closures, async/await if Swift concurrency is adopted) for long-running tasks.
- **Clear State Management**: If the onboarding process involves multiple steps or states, this should be managed clearly.

## 4. Internal and External Dependencies

### Internal Dependencies (Potential):
- **`utils` directory**: For device information (`DeviceUtil`), logging (`LogUtil`), or network operations (`NetworkUtil`) if registration or configuration fetching is needed.
- **`connectors` directory**: If onboarding involves sending data to or receiving data from a backend (e.g., via `WebSocketConnector` or a dedicated HTTP connector).
- **`protocols` directory**: For defining data structures used in communication during onboarding.
- **`adapters` directory**: If onboarding requires interaction with native platform features like permissions or specific settings.

### External Dependencies (Potential):
- **Foundation**: For basic data types and utilities.
- **UIKit**: If UI elements are part of the onboarding flow.

## 5. State Management

- **Onboarding State**: If the onboarding process is multi-step, the SDK might need to manage the current state of onboarding (e.g., `notStarted`, `inProgress`, `completed`, `failed`). This could be stored in `UserDefaults` (via `PreferenceAdapter`) or in memory.
- **Configuration Data**: Any configuration data fetched or set during onboarding would need to be stored appropriately, potentially using `PreferenceAdapter` or a dedicated configuration manager.

Since the directory is currently empty, there is no active state management within it.