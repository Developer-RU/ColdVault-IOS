# Architecture

ColdVault uses an MVVM architecture tailored for SwiftUI.

## Layered Structure

- App layer:
  - App lifecycle handling.
  - Dependency wiring and root composition.
- View layer:
  - SwiftUI screens and reusable visual components.
  - No heavy business logic.
- ViewModel layer:
  - State orchestration and user flow coordination.
  - Calls service APIs and maps results to view state.
- Service layer:
  - Security operations, wallet handling, QR encode/decode, backup operations.
- Model layer:
  - Domain entities for wallets, settings, events, and drafts.

## Dependency Direction

Views -> ViewModels -> Services -> Models

Rules:

- Views should not directly perform sensitive operations.
- Services remain framework-light and reusable.
- Models stay independent from UI concerns.

## App Composition

`ColdVaultApp` wires dependencies during app startup and injects the top-level view model into the SwiftUI environment.

## Extension Points

- Add a new blockchain network by extending model definitions and network adapter/service paths.
- Add new app settings by extending settings models and the corresponding settings view model bindings.
- Add new security events by introducing normalized event types in the model and localized labels in resources.
