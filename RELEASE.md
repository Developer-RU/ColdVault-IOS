# Release Process

This document describes how releases are prepared and published for ColdVault.

## Versioning

ColdVault follows Semantic Versioning where possible:

- MAJOR: incompatible API or behavior changes.
- MINOR: backward-compatible functionality additions.
- PATCH: backward-compatible fixes.

Example: `v1.2.3`.

## Release Checklist

1. Ensure `main` is green in CI.
2. Confirm documentation updates are complete:
   - `README.md`
   - `CHANGELOG.md`
   - relevant wiki pages in `docs/wiki`
3. Verify app builds in Xcode and with terminal command:
   - `xcodebuild -project ColdVault.xcodeproj -scheme ColdVault -destination 'generic/platform=iOS Simulator' build`
4. Update `CHANGELOG.md`:
   - Move relevant items from `Unreleased` into a new version section.
   - Add date in `YYYY-MM-DD` format.
5. Create and push the release tag:
   - `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
   - `git push origin vX.Y.Z`
6. Publish GitHub Release notes using the changelog summary.

## Hotfix Releases

For urgent production issues:

1. Branch from the latest release tag.
2. Apply only minimal required fixes.
3. Open PR with explicit "hotfix" label.
4. Cut patch release (`PATCH` increment).

## Security Fixes

If release includes security-sensitive changes:

1. Follow coordinated disclosure guidance in `SECURITY.md`.
2. Avoid exposing exploit details before users can update.
3. Include clear upgrade guidance in release notes.
