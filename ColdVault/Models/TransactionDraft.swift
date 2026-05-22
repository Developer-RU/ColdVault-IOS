import Foundation

struct TransactionDraft: Identifiable, Codable {
    let id: UUID
    var fromAddress: String
    var toAddress: String
    var amount: Decimal
    var memo: String
    var timestamp: Date

    init(
        id: UUID = UUID(),
        fromAddress: String,
        toAddress: String,
        amount: Decimal,
        memo: String,
        timestamp: Date = .now
    ) {
        self.id = id
        self.fromAddress = fromAddress
        self.toAddress = toAddress
        self.amount = amount
        self.memo = memo
        self.timestamp = timestamp
    }
}

struct SignedTransaction: Identifiable, Codable {
    let id: UUID
    var payload: TransactionDraft
    var signature: String
    var signedBy: String
    var exportedAt: Date

    init(
        id: UUID = UUID(),
        payload: TransactionDraft,
        signature: String,
        signedBy: String,
        exportedAt: Date = .now
    ) {
        self.id = id
        self.payload = payload
        self.signature = signature
        self.signedBy = signedBy
        self.exportedAt = exportedAt
    }
}
