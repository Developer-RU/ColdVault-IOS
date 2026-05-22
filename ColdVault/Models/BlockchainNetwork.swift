import Foundation

/// Supported blockchain families displayed and used for wallet creation.
enum BlockchainFamily: String, Codable, CaseIterable, Identifiable {
    case bitcoin
    case litecoin
    case ethereum
    case bsc
    case polygon
    case avalanche
    case arbitrum
    case optimism
    case tron
    case solana
    case ton

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .bitcoin:
            return "network.bitcoin"
        case .litecoin:
            return "network.litecoin"
        case .ethereum:
            return "network.ethereum"
        case .bsc:
            return "network.bsc"
        case .polygon:
            return "network.polygon"
        case .avalanche:
            return "network.avalanche"
        case .arbitrum:
            return "network.arbitrum"
        case .optimism:
            return "network.optimism"
        case .tron:
            return "network.tron"
        case .solana:
            return "network.solana"
        case .ton:
            return "network.ton"
        }
    }
}

/// Deployment environment for a blockchain network.
enum NetworkEnvironment: String, Codable, CaseIterable, Identifiable {
    case testnet
    case mainnet

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .testnet:
            return "network.testnet"
        case .mainnet:
            return "network.mainnet"
        }
    }
}

/// A concrete blockchain network identity (family + environment).
struct BlockchainNetwork: Codable, Hashable, Identifiable {
    var family: BlockchainFamily
    var environment: NetworkEnvironment

    var id: String {
        "\(family.rawValue)-\(environment.rawValue)"
    }

    var displayName: String {
        "\(String(localized: String.LocalizationValue(family.titleKey))) \(String(localized: String.LocalizationValue(environment.titleKey)))"
    }

    func localizedDisplayName(locale: Locale) -> String {
        let bundle = Bundle.localizedBundle(for: locale)
        let familyName = NSLocalizedString(family.titleKey, bundle: bundle, comment: "")
        let environmentName = NSLocalizedString(environment.titleKey, bundle: bundle, comment: "")
        return "\(familyName) \(environmentName)"
    }

    static let bitcoinTestnet = BlockchainNetwork(family: .bitcoin, environment: .testnet)
    static let bitcoinMainnet = BlockchainNetwork(family: .bitcoin, environment: .mainnet)
    static let litecoinMainnet = BlockchainNetwork(family: .litecoin, environment: .mainnet)
    static let ethereumTestnet = BlockchainNetwork(family: .ethereum, environment: .testnet)
    static let ethereumMainnet = BlockchainNetwork(family: .ethereum, environment: .mainnet)
    static let bscMainnet = BlockchainNetwork(family: .bsc, environment: .mainnet)
    static let polygonMainnet = BlockchainNetwork(family: .polygon, environment: .mainnet)
    static let avalancheMainnet = BlockchainNetwork(family: .avalanche, environment: .mainnet)
    static let arbitrumMainnet = BlockchainNetwork(family: .arbitrum, environment: .mainnet)
    static let optimismMainnet = BlockchainNetwork(family: .optimism, environment: .mainnet)
    static let tronMainnet = BlockchainNetwork(family: .tron, environment: .mainnet)
    static let solanaMainnet = BlockchainNetwork(family: .solana, environment: .mainnet)
    static let tonMainnet = BlockchainNetwork(family: .ton, environment: .mainnet)

    static let all: [BlockchainNetwork] = [
        .bitcoinTestnet,
        .bitcoinMainnet,
        .litecoinMainnet,
        .ethereumTestnet,
        .ethereumMainnet,
        .bscMainnet,
        .polygonMainnet,
        .avalancheMainnet,
        .arbitrumMainnet,
        .optimismMainnet,
        .tronMainnet,
        .solanaMainnet,
        .tonMainnet
    ]

    static let modernMainnets: [BlockchainNetwork] = [
        .bitcoinMainnet,
        .litecoinMainnet,
        .ethereumMainnet,
        .bscMainnet,
        .polygonMainnet,
        .avalancheMainnet,
        .arbitrumMainnet,
        .optimismMainnet,
        .tronMainnet,
        .solanaMainnet,
        .tonMainnet
    ]
}

private extension Bundle {
    static func localizedBundle(for locale: Locale) -> Bundle {
        if let code = locale.language.languageCode?.identifier,
           let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }
}
