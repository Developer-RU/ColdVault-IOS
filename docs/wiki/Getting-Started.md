# Getting Started

## Prerequisites

- macOS with latest stable Xcode installed.
- Xcode Command Line Tools.
- XcodeGen:
  - `brew install xcodegen`

## Clone and Build

1. Clone the repository.
2. Open terminal in repository root.
3. Generate project:
   - `xcodegen generate`
4. Open `ColdVault.xcodeproj` in Xcode.
5. Select `ColdVault` scheme.
6. Run on iOS Simulator or physical iPhone.

## Build via Terminal

```bash
xcodebuild -project ColdVault.xcodeproj -scheme ColdVault -destination 'generic/platform=iOS Simulator' build
```

## Quick Orientation

- `ColdVault/App`: app entry and app-level composition.
- `ColdVault/Views`: SwiftUI screens and reusable components.
- `ColdVault/Services`: core business/security and integration logic.
- `ColdVault/Models`: domain entities and app settings.
- `ColdVault/Resources`: localization and assets.

## First Contribution in 10 Minutes

1. Pick an issue labeled `good first issue` (if available).
2. Create a branch from `main`.
3. Make focused changes.
4. Validate build locally.
5. Open PR using the repository template.
