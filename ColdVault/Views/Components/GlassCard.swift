import SwiftUI

enum CVDesign {
    static let accent = Color.cyan
    static let cornerRadius: CGFloat = 12
    static let cardCornerRadius: CGFloat = 24
    static let fieldFill = Color.secondary.opacity(0.08)
    static let fieldStroke = Color.white.opacity(0.18)
}

private struct CVPrimaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .lineLimit(2)
            .minimumScaleFactor(0.78)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(.white)
            .frame(minHeight: 38)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: CVDesign.cornerRadius, style: .continuous)
                    .fill(CVDesign.accent.opacity(configuration.isPressed ? 0.82 : 0.98))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CVDesign.cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(configuration.isPressed ? 0.16 : 0.26), lineWidth: 0.8)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

private struct CVSecondaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .lineLimit(2)
            .minimumScaleFactor(0.78)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .foregroundStyle(CVDesign.accent)
            .frame(minHeight: 36)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: CVDesign.cornerRadius, style: .continuous)
                    .fill(CVDesign.accent.opacity(configuration.isPressed ? 0.12 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CVDesign.cornerRadius, style: .continuous)
                    .strokeBorder(CVDesign.accent.opacity(configuration.isPressed ? 0.45 : 0.28), lineWidth: 0.8)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

private struct CVDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .lineLimit(2)
            .minimumScaleFactor(0.78)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(.white)
            .frame(minHeight: 38)
            .background(
                RoundedRectangle(cornerRadius: CVDesign.cornerRadius, style: .continuous)
                    .fill(Color.red.opacity(configuration.isPressed ? 0.78 : 0.94))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CVDesign.cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(configuration.isPressed ? 0.16 : 0.24), lineWidth: 0.8)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

private struct CardEntranceModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 16)
            .scaleEffect(isVisible ? 1 : 0.985)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.84).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func cvInputField() -> some View {
        padding(10)
            .background(CVDesign.fieldFill, in: RoundedRectangle(cornerRadius: CVDesign.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CVDesign.cornerRadius, style: .continuous)
                    .strokeBorder(CVDesign.fieldStroke, lineWidth: 0.6)
            )
    }

    func cvPrimaryAction() -> some View {
        buttonStyle(CVPrimaryButtonStyle())
    }

    func cvPrimaryActionFullWidth() -> some View {
        buttonStyle(CVPrimaryButtonStyle(fullWidth: true))
    }

    func cvSecondaryAction() -> some View {
        buttonStyle(CVSecondaryButtonStyle())
    }

    func cvSecondaryActionFullWidth() -> some View {
        buttonStyle(CVSecondaryButtonStyle(fullWidth: true))
    }

    func cvDestructiveAction() -> some View {
        buttonStyle(CVDestructiveButtonStyle())
    }

    func cvCardEntrance(delay: Double = 0) -> some View {
        modifier(CardEntranceModifier(delay: delay))
    }
}

private extension BlockchainFamily {
    var ticker: String {
        switch self {
        case .bitcoin:
            return "BTC"
        case .litecoin:
            return "LTC"
        case .ethereum:
            return "ETH"
        case .bsc:
            return "BSC"
        case .polygon:
            return "POL"
        case .avalanche:
            return "AVX"
        case .arbitrum:
            return "ARB"
        case .optimism:
            return "OP"
        case .tron:
            return "TRX"
        case .solana:
            return "SOL"
        case .ton:
            return "TON"
        }
    }

    var symbolName: String {
        switch self {
        case .bitcoin:
            return "bitcoinsign"
        case .litecoin:
            return "l.circle"
        case .ethereum:
            return "e.circle"
        case .bsc:
            return "b.circle"
        case .polygon:
            return "p.circle"
        case .avalanche:
            return "mountain.2"
        case .arbitrum:
            return "a.circle"
        case .optimism:
            return "o.circle"
        case .tron:
            return "t.circle"
        case .solana:
            return "s.circle"
        case .ton:
            return "bolt.circle"
        }
    }

    var iconGradient: [Color] {
        switch self {
        case .bitcoin:
            return [Color.orange, Color.yellow]
        case .litecoin:
            return [Color.gray, Color.blue.opacity(0.7)]
        case .ethereum:
            return [Color.indigo, Color.cyan]
        case .bsc:
            return [Color.yellow, Color.orange]
        case .polygon:
            return [Color.pink, Color.purple]
        case .avalanche:
            return [Color.red, Color.orange]
        case .arbitrum:
            return [Color.blue, Color.indigo]
        case .optimism:
            return [Color.red, Color.pink]
        case .tron:
            return [Color.red, Color.mint]
        case .solana:
            return [Color.mint, Color.teal]
        case .ton:
            return [Color.blue, Color.cyan]
        }
    }
}

struct CurrencyIconView: View {
    let network: BlockchainNetwork
    var size: CGFloat = 28

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: network.family.iconGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: network.family.symbolName)
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(.white)

                // Keep ticker as a subtle fallback signature for currencies with generic SF Symbols.
                Text(network.family.ticker)
                    .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .offset(y: size * 0.24)
            }

            Circle()
                .fill(network.environment == .mainnet ? Color.green : Color.orange)
                .frame(width: size * 0.28, height: size * 0.28)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.9), lineWidth: 0.8)
                )
                .offset(x: size * 0.02, y: size * 0.02)
        }
        .frame(width: size, height: size)
        .overlay(
            Circle()
                .strokeBorder(Color.white.opacity(0.28), lineWidth: 0.8)
        )
        .shadow(color: .black.opacity(0.16), radius: 6, y: 3)
        .accessibilityHidden(true)
    }
}

struct GlassCard<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.footnote.weight(.bold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(.secondary.opacity(0.9))
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CVDesign.cardCornerRadius, style: .continuous)
                .fill(Color(uiColor: .systemBackground).opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: CVDesign.cardCornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.45),
                                    .white.opacity(0.08),
                                    CVDesign.accent.opacity(0.28)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
        )
        .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
    }
}
