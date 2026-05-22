import CryptoKit
import Foundation

protocol WalletServiceProtocol {
    func loadWallets() -> [Wallet]
    func saveWallets(_ wallets: [Wallet])
    func createWallet(name: String, network: BlockchainNetwork, preferSecureEnclave: Bool) throws -> Wallet
    func signTransaction(_ draft: TransactionDraft, with wallet: Wallet) throws -> SignedTransaction
    func exportSignedTransaction(_ signed: SignedTransaction, wallet: Wallet) throws -> String
}

enum WalletServiceError: LocalizedError {
    case walletEncodingError
    case walletDecodingError

    var errorDescription: String? {
        switch self {
        case .walletEncodingError:
            return String(localized: "service.wallet.encoding_error")
        case .walletDecodingError:
            return String(localized: "service.wallet.decoding_error")
        }
    }
}

final class WalletService: WalletServiceProtocol {
    private let walletsKey = "coldvault.wallets"
    private let securityService: SecurityServiceProtocol
    private let networkRegistry: NetworkAdapterRegistry
    private let defaults: UserDefaults

    init(
        securityService: SecurityServiceProtocol,
        networkRegistry: NetworkAdapterRegistry = NetworkAdapterRegistry(),
        defaults: UserDefaults = .standard
    ) {
        self.securityService = securityService
        self.networkRegistry = networkRegistry
        self.defaults = defaults
    }

    func loadWallets() -> [Wallet] {
        guard let data = defaults.data(forKey: walletsKey) else {
            return []
        }
        return (try? JSONDecoder().decode([Wallet].self, from: data)) ?? []
    }

    func saveWallets(_ wallets: [Wallet]) {
        if let data = try? JSONEncoder().encode(wallets) {
            defaults.set(data, forKey: walletsKey)
        }
    }

    func createWallet(name: String, network: BlockchainNetwork, preferSecureEnclave: Bool) throws -> Wallet {
        let label = UUID().uuidString
        let keyPair = try securityService.generatePrivateKeyReference(label: label, preferSecureEnclave: preferSecureEnclave)
        let adapter = try networkRegistry.adapter(for: network)
        let address = adapter.deriveAddress(from: keyPair.publicKey)

        return Wallet(
            name: name,
            address: address,
            network: network,
            publicKey: keyPair.publicKey,
            privateKeyReference: keyPair.reference,
            balance: 0,
            isDemo: false
        )
    }

    func signTransaction(_ draft: TransactionDraft, with wallet: Wallet) throws -> SignedTransaction {
        let payloadData = try JSONEncoder().encode(draft)
        let signatureData = try securityService.sign(data: payloadData, privateKeyReference: wallet.privateKeyReference)
        return SignedTransaction(
            payload: draft,
            signature: signatureData.base64EncodedString(),
            signedBy: wallet.address
        )
    }

    func exportSignedTransaction(_ signed: SignedTransaction, wallet: Wallet) throws -> String {
        let adapter = try networkRegistry.adapter(for: wallet.network)
        return try adapter.wrapSignedTransaction(signed)
    }
}
