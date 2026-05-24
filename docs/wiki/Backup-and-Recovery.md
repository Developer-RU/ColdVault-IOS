# Backup and Recovery

## Goals

- Protect users from data loss.
- Ensure backup confidentiality.
- Support deterministic restoration of app state.

## Backup Guidance

- Encrypt backups before export.
- Require user-selected passphrase for encryption/decryption.
- Avoid storing backup files in publicly shared or weakly protected locations.

## Recovery Guidance

- Validate backup structure before attempting full import.
- Reject backups with invalid format or failed cryptographic checks.
- Show clear user-facing recovery outcomes (success, partial, failure).

## Recommended Validation Cases

- Wrong passphrase.
- Corrupted backup content.
- Incompatible schema/version.
- Missing required wallet fields.

## Data Hygiene

- Never include private keys or seed phrases in logs.
- Avoid crash reports that contain sensitive cryptographic payloads.
