# QR Air-Gap Flow

This document describes the intended high-level flow for offline payload exchange using QR codes.

## Typical Flow

1. Construct unsigned transaction data on an online device/system.
2. Convert payload into QR.
3. Scan payload in ColdVault on an offline or restricted device.
4. Validate payload and sign transaction locally.
5. Export signed payload as QR.
6. Scan signed payload back on the online system for network broadcast.

## Validation Requirements

Before signing, verify:

- Target network and chain context.
- Destination address.
- Amount and fee values.
- Nonce/index consistency.

## UX and Safety Recommendations

- Present a clear human-readable transaction summary before signing.
- Require explicit user confirmation before cryptographic signing.
- Display warnings when payload fields are malformed or incomplete.

## Error Handling

Handle these classes of errors explicitly:

- Invalid QR format or unsupported schema version.
- Truncated payload or checksum mismatch.
- Unsupported network identifier.
- Signature operation failure.
