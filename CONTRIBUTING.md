# Contributing to ColdVault

Thank you for your interest in improving ColdVault.

## Ground rules

- Keep changes focused and easy to review.
- Prefer small pull requests over large, multi-topic PRs.
- Preserve existing architecture patterns (MVVM, service boundaries).
- Do not commit secrets, private keys, or local machine artifacts.

## Development setup

1. Install Xcode and command line tools.
2. Install XcodeGen:
   - `brew install xcodegen`
3. Generate project:
   - `xcodegen generate`
4. Build locally:
   - `xcodebuild -project ColdVault.xcodeproj -scheme ColdVault -destination 'generic/platform=iOS Simulator' build`

## Coding guidelines

- Use SwiftUI and keep views declarative.
- Keep business logic in view models/services, not in views.
- Add concise comments only when logic is non-obvious.
- Keep localization keys synchronized across `en.lproj` and `ru.lproj`.
- Avoid introducing breaking behavior without clear migration paths.

## Pull request checklist

- Code builds successfully.
- New behavior is tested manually on simulator and, when relevant, on a device.
- Localization keys are added for both English and Russian.
- No personal data, local logs, or generated artifacts are included.
- PR description explains what changed and why.

## Commit message suggestions

Use clear, action-oriented messages, for example:

- `Add auto-clear logs setting`
- `Fix biometric re-auth race on scene active`
- `Improve QR scanner overlay visuals`

## Reporting bugs

Please use the bug report template and include:

- Device type (iPhone model or simulator)
- iOS version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots or logs (without sensitive data)
