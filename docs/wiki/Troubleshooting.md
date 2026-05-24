# Troubleshooting

## Project Does Not Build

Checklist:

1. Run `xcodegen generate` before opening project.
2. Verify you are on supported Xcode version.
3. Clean build folder in Xcode.
4. Re-run terminal build command from README.

## Camera / QR Scanner Issues

- Ensure simulator/device camera permissions are granted.
- On simulator, camera behavior is limited compared to real hardware.
- Verify payload format matches expected schema.

## Biometric Authentication Not Triggering

- Check Face ID/Touch ID availability on test device.
- Confirm permission prompts were accepted.
- Re-test on physical device if simulator behavior differs.

## Localization Not Updating

- Verify key exists in both locale files.
- Confirm app language setting changed and view refreshed.
- Restart app to confirm no stale state remains.

## Getting More Help

If issue persists, open a support issue and include reproducible steps and environment details.
