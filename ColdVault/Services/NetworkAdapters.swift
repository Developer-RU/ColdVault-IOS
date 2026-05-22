import CryptoKit
import Foundation

protocol BlockchainNetworkAdapter {
    var supportedNetwork: BlockchainNetwork { get }
    func deriveAddress(from publicKey: String) -> String
    func wrapSignedTransaction(_ signed: SignedTransaction) throws -> String
}

enum NetworkAdapterError: LocalizedError {
    case adapterNotFound
    case exportError

    var errorDescription: String? {
        switch self {
        case .adapterNotFound:
            return String(localized: "service.network.adapter_not_found")
        case .exportError:
            return String(localized: "service.network.export_error")
        }
    }
}

struct NetworkSignedEnvelope: Codable {
    var networkID: String
    var payload: SignedTransaction
    var exportVersion: String
}

private struct BitcoinLikeAdapter: BlockchainNetworkAdapter {
    let supportedNetwork: BlockchainNetwork

    func deriveAddress(from publicKey: String) -> String {
        let hex = sha256Hex(publicKey)
        let prefix: String
        switch supportedNetwork.family {
        case .bitcoin:
            prefix = supportedNetwork.environment == .mainnet ? "bc1cv" : "tb1cv"
        case .litecoin:
            prefix = supportedNetwork.environment == .mainnet ? "ltc1cv" : "tltc1cv"
        default:
            prefix = "cv"
        }
        return "\(prefix)\(hex.prefix(36))"
    }

    func wrapSignedTransaction(_ signed: SignedTransaction) throws -> String {
        try exportEnvelope(signed, version: "utxo-adapter-v1")
    }
}

private struct EVMAdapter: BlockchainNetworkAdapter {
    let supportedNetwork: BlockchainNetwork

    func deriveAddress(from publicKey: String) -> String {
        let hex = sha256Hex(publicKey)
        return "0x\(hex.suffix(40))"
    }

    func wrapSignedTransaction(_ signed: SignedTransaction) throws -> String {
        try exportEnvelope(signed, version: "evm-adapter-v1")
    }
}

private struct TronAdapter: BlockchainNetworkAdapter {
    let supportedNetwork: BlockchainNetwork

    func deriveAddress(from publicKey: String) -> String {
        let hex = sha256Hex(publicKey)
        return "T\(hex.prefix(33))"
    }

    func wrapSignedTransaction(_ signed: SignedTransaction) throws -> String {
        try exportEnvelope(signed, version: "tron-adapter-v1")
    }
}

private struct SolanaAdapter: BlockchainNetworkAdapter {
    let supportedNetwork: BlockchainNetwork

    func deriveAddress(from publicKey: String) -> String {
        // Deterministic base58-like string for offline/local demo addressing.
        let digest = SHA256.hash(data: Data(publicKey.utf8))
        let alphabet = Array("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")
        var out = ""
        for byte in digest.prefix(32) {
            out.append(alphabet[Int(byte) % alphabet.count])
        }
        return out
    }

    func wrapSignedTransaction(_ signed: SignedTransaction) throws -> String {
        try exportEnvelope(signed, version: "solana-adapter-v1")
    }
}

private struct TonAdapter: BlockchainNetworkAdapter {
    let supportedNetwork: BlockchainNetwork

    func deriveAddress(from publicKey: String) -> String {
        let digest = SHA256.hash(data: Data(publicKey.utf8))
        let data = Data(digest).prefix(32)
        let b64 = Data(data).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "EQ\(b64.prefix(46))"
    }

    func wrapSignedTransaction(_ signed: SignedTransaction) throws -> String {
        try exportEnvelope(signed, version: "ton-adapter-v1")
    }
}

private func sha256Hex(_ value: String) -> String {
    let digest = SHA256.hash(data: Data(value.utf8))
    return digest.compactMap { String(format: "%02x", $0) }.joined()
}

private func exportEnvelopeForNetwork(_ signed: SignedTransaction, version: String, network: BlockchainNetwork) throws -> String {
    let envelope = NetworkSignedEnvelope(
        networkID: network.id,
        payload: signed,
        exportVersion: version
    )
    let data = try JSONEncoder().encode(envelope)
    guard let out = String(data: data, encoding: .utf8) else {
        throw NetworkAdapterError.exportError
    }
    return out
}

private extension BlockchainNetworkAdapter {
    func exportEnvelope(_ signed: SignedTransaction, version: String) throws -> String {
        try exportEnvelopeForNetwork(signed, version: version, network: supportedNetwork)
    }
}

final class NetworkAdapterRegistry {
    private var adapters: [String: BlockchainNetworkAdapter] = [:]

    init() {
        for network in BlockchainNetwork.all {
            register(makeAdapter(for: network))
        }
    }

    func register(_ adapter: BlockchainNetworkAdapter) {
        adapters[adapter.supportedNetwork.id] = adapter
    }

    func adapter(for network: BlockchainNetwork) throws -> BlockchainNetworkAdapter {
        guard let adapter = adapters[network.id] else {
            throw NetworkAdapterError.adapterNotFound
        }
        return adapter
    }

    private func makeAdapter(for network: BlockchainNetwork) -> BlockchainNetworkAdapter {
        switch network.family {
        case .bitcoin, .litecoin:
            return BitcoinLikeAdapter(supportedNetwork: network)
        case .ethereum, .bsc, .polygon, .avalanche, .arbitrum, .optimism:
            return EVMAdapter(supportedNetwork: network)
        case .tron:
            return TronAdapter(supportedNetwork: network)
        case .solana:
            return SolanaAdapter(supportedNetwork: network)
        case .ton:
            return TonAdapter(supportedNetwork: network)
        }
    }
}
