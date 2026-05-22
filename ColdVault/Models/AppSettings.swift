import Foundation

/// Persisted user preferences controlling security, UI, language, and logs behavior.
struct AppSettings: Codable {
    var requireBiometricOnLaunch: Bool = true
    var useSecureEnclaveWhenAvailable: Bool = true
    var selectedNetwork: BlockchainNetwork = .bitcoinTestnet
    var appTheme: AppTheme = .system
    var appLanguage: AppLanguage = .system
    var autoClearLogsOnLaunch: Bool = false

    enum CodingKeys: String, CodingKey {
        case requireBiometricOnLaunch
        case useSecureEnclaveWhenAvailable
        case selectedNetwork
        case appTheme
        case appLanguage
        case autoClearLogsOnLaunch
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        requireBiometricOnLaunch = try container.decodeIfPresent(Bool.self, forKey: .requireBiometricOnLaunch) ?? true
        useSecureEnclaveWhenAvailable = try container.decodeIfPresent(Bool.self, forKey: .useSecureEnclaveWhenAvailable) ?? true
        selectedNetwork = try container.decodeIfPresent(BlockchainNetwork.self, forKey: .selectedNetwork) ?? .bitcoinTestnet
        appTheme = try container.decodeIfPresent(AppTheme.self, forKey: .appTheme) ?? .system
        appLanguage = try container.decodeIfPresent(AppLanguage.self, forKey: .appLanguage) ?? .system
        autoClearLogsOnLaunch = try container.decodeIfPresent(Bool.self, forKey: .autoClearLogsOnLaunch) ?? false
    }
}

/// Serializable payload exchanged between devices via QR.
struct ExchangePayload: Codable {
    var kind: String
    var body: String
    var sourceDevice: String
    var createdAt: Date
    var correlationID: String?
}
