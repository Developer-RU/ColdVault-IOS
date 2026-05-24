# Development and Contributing

For contribution basics, see `CONTRIBUTING.md`.

## Branch Strategy

- `main` is the default integration branch.
- Use short-lived feature/fix branches.
- Keep pull requests focused to a single concern.

## Quality Gates

Before opening PR:

1. Build project successfully.
2. Validate primary user flows manually.
3. Confirm localization updates in both supported languages.
4. Ensure no sensitive data or generated artifacts are committed.

## Suggested PR Scope

Good PR:

- One feature or one bugfix.
- Includes docs updates where relevant.
- Includes before/after screenshots for UI changes.

Avoid PRs that mix unrelated refactors, style-only changes, and feature work.

## Commit Message Pattern

Use concise, action-oriented messages:

- `Fix scene phase auth race`
- `Add backup import error states`
- `Improve QR scanner payload validation`
