import Foundation

struct Wallet: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var address: String
    var network: BlockchainNetwork
    var publicKey: String
    var privateKeyReference: String
    var balance: Decimal
    var isDemo: Bool

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        network: BlockchainNetwork = .bitcoinTestnet,
        publicKey: String,
        privateKeyReference: String,
        balance: Decimal = 0,
        isDemo: Bool = false
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.network = network
        self.publicKey = publicKey
        self.privateKeyReference = privateKeyReference
        self.balance = balance
        self.isDemo = isDemo
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case network
        case publicKey
        case privateKeyReference
        case balance
        case isDemo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        network = try container.decodeIfPresent(BlockchainNetwork.self, forKey: .network) ?? .bitcoinTestnet
        publicKey = try container.decode(String.self, forKey: .publicKey)
        privateKeyReference = try container.decode(String.self, forKey: .privateKeyReference)
        balance = try container.decodeIfPresent(Decimal.self, forKey: .balance) ?? 0
        isDemo = try container.decodeIfPresent(Bool.self, forKey: .isDemo) ?? false
    }
}
