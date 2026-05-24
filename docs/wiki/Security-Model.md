# Security Model

## Security Objectives

- Keep private key material local to the device.
- Minimize online attack surface for signing workflows.
- Require explicit user authentication before sensitive actions.
- Protect backup payload confidentiality.

## Key Principles

- Local-first key handling:
  - Key generation and storage are performed on-device.
- Hardware-backed protection where available:
  - Secure Enclave path is used when supported by hardware and configuration.
- Session access protection:
  - Biometric checks (Face ID / Touch ID) gate app access and sensitive operations.
- Air-gapped transfer model:
  - QR payload exchange is preferred for offline workflows.

## Threat Considerations

ColdVault is designed to reduce common risks but does not eliminate all threats.

Examples:

- Device compromise can still expose local app data.
- Shoulder-surfing or camera interception can leak QR payloads.
- Weak backup passphrases can reduce effective encryption strength.

## Operational Guidance

- Use strong passphrases for backup encryption.
- Prefer physical device tests for biometric/security behavior (simulator differs).
- Keep iOS and app versions updated.
- Avoid sharing screenshots containing keys or sensitive payloads.

## Vulnerability Reporting

Follow `SECURITY.md` for coordinated disclosure.
