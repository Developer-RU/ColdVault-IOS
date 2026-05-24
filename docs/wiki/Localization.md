# Localization

ColdVault currently supports English and Russian.

## Resource Files

- `ColdVault/Resources/en.lproj/Localizable.strings`
- `ColdVault/Resources/ru.lproj/Localizable.strings`

## Rules

- Add new keys in both locales in the same pull request.
- Keep key names stable and descriptive.
- Avoid embedding user-visible strings directly in Swift code when localization is expected.

## Translation Quality Checklist

- Technical terms are consistent across screens.
- Security warnings are explicit and unambiguous.
- Character limits are verified on smaller iPhone screens.

## Runtime Language Switching

ColdVault supports runtime language switching through app settings.

Contributors should validate language switch flow after adding new strings.
