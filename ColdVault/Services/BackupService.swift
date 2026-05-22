import CryptoKit
import Foundation

protocol BackupServiceProtocol {
    func encryptBackup(plainData: Data, passphrase: String) throws -> String
    func decryptBackup(encryptedString: String, passphrase: String) throws -> Data
}

enum BackupServiceError: LocalizedError {
    case invalidPassphrase
    case encodingFailed
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .invalidPassphrase:
            return String(localized: "service.backup.invalid_passphrase")
        case .encodingFailed:
            return String(localized: "service.backup.encoding_failed")
        case .invalidPayload:
            return String(localized: "service.backup.invalid_payload")
        }
    }
}

struct EncryptedBackupEnvelope: Codable {
    var algorithm: String
    var salt: String
    var nonce: String
    var ciphertext: String
    var tag: String
    var createdAt: Date
}

final class BackupService: BackupServiceProtocol {
    func encryptBackup(plainData: Data, passphrase: String) throws -> String {
        let normalized = passphrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            throw BackupServiceError.invalidPassphrase
        }

        let salt = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        let key = deriveKey(passphrase: normalized, salt: salt)
        let sealed = try ChaChaPoly.seal(plainData, using: key)

        let envelope = EncryptedBackupEnvelope(
            algorithm: "ChaChaPoly-v1",
            salt: salt.base64EncodedString(),
            nonce: Data(sealed.nonce).base64EncodedString(),
            ciphertext: sealed.ciphertext.base64EncodedString(),
            tag: sealed.tag.base64EncodedString(),
            createdAt: .now
        )

        let data = try JSONEncoder().encode(envelope)
        guard let out = String(data: data, encoding: .utf8) else {
            throw BackupServiceError.encodingFailed
        }
        return out
    }

    func decryptBackup(encryptedString: String, passphrase: String) throws -> Data {
        guard let data = encryptedString.data(using: .utf8) else {
            throw BackupServiceError.invalidPayload
        }
        let envelope = try JSONDecoder().decode(EncryptedBackupEnvelope.self, from: data)

        guard
            let salt = Data(base64Encoded: envelope.salt),
            let nonceData = Data(base64Encoded: envelope.nonce),
            let ciphertext = Data(base64Encoded: envelope.ciphertext),
            let tag = Data(base64Encoded: envelope.tag)
        else {
            throw BackupServiceError.invalidPayload
        }

        let key = deriveKey(passphrase: passphrase, salt: salt)
        let nonce = try ChaChaPoly.Nonce(data: nonceData)
        let sealed = try ChaChaPoly.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        return try ChaChaPoly.open(sealed, using: key)
    }

    private func deriveKey(passphrase: String, salt: Data) -> SymmetricKey {
        let base = Data(passphrase.utf8) + salt
        let digest = SHA256.hash(data: base)
        return SymmetricKey(data: Data(digest))
    }
}
