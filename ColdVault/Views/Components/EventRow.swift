import SwiftUI

struct EventRow: View {
    @EnvironmentObject private var viewModel: ColdVaultViewModel
    let event: SecurityEvent

    private var resolvedLocale: Locale {
        let locale = viewModel.settings.appLanguage.locale
        return locale.identifier.isEmpty ? Locale.current : locale
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.cyan.opacity(0.85))
                .frame(width: 9, height: 9)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 5) {
                Text(event.localizedTitle(locale: resolvedLocale))
                    .font(.subheadline.weight(.semibold))
                Text(event.localizedDetail(locale: resolvedLocale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(event.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
