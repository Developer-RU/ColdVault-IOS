# Security Policy

## Supported versions

ColdVault is currently maintained on the latest main branch in this repository.

## Reporting a vulnerability

If you believe you found a security issue, please do not disclose it publicly first.

Send a private report that includes:

- A clear description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested remediation if available

If direct private contact is not configured yet, open a minimal GitHub issue without exploit details and request a secure communication channel.

## Scope notes

ColdVault handles sensitive cryptographic operations. Please prioritize reports related to:

- Key generation and storage
- Secure Enclave and keychain handling
- Authentication and session lock behavior
- Backup encryption/decryption
- QR payload import/export validation
- Logging of sensitive information

## Safe disclosure expectations

- Allow reasonable time for triage and patching.
- Avoid sharing proof-of-concept exploits publicly before a fix is available.
- Provide enough technical detail for maintainers to reproduce the issue.

## Data handling reminder

Never include real private keys, seed phrases, wallet credentials, or other sensitive secrets in reports.
