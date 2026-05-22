import CryptoKit
import Foundation
import LocalAuthentication
import Security

/// Defines cryptographic and local-authentication capabilities used by the app.
protocol SecurityServiceProtocol {
    func authenticateWithBiometrics(reason: String) async throws
    func generatePrivateKeyReference(label: String, preferSecureEnclave: Bool) throws -> (reference: String, publicKey: String)
    func sign(data: Data, privateKeyReference: String) throws -> Data
    func store(_ data: Data, for key: String) throws
    func read(for key: String) throws -> Data?
}

/// Unified error set for cryptography, keychain, and biometric operations.
enum SecurityServiceError: LocalizedError {
    case keyGenerationFailed
    case keyNotFound
    case signingFailed
    case keychainError(OSStatus)
    case biometricsUnavailable

    var errorDescription: String? {
        switch self {
        case .keyGenerationFailed:
            return String(localized: "service.security.key_generation_failed")
        case .keyNotFound:
            return String(localized: "service.security.key_not_found")
        case .signingFailed:
            return String(localized: "service.security.signing_failed")
        case let .keychainError(status):
            return String(
                format: String(localized: "service.security.keychain_error"),
                locale: Locale.current,
                status
            )
        case .biometricsUnavailable:
            return String(localized: "service.security.biometrics_unavailable")
        }
    }
}

/// Production implementation backed by Keychain, Secure Enclave, and LocalAuthentication.
final class SecurityService: SecurityServiceProtocol {
    private let service = "com.coldvault.security"

    func authenticateWithBiometrics(reason: String) async throws {
        let context = LAContext()
        context.localizedFallbackTitle = ""
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let authError = error,
               authError.domain == LAError.errorDomain,
               authError.code == LAError.biometryLockout.rawValue {
                try await evaluate(policy: .deviceOwnerAuthentication, context: context, reason: reason)
                return
            }
            throw SecurityServiceError.biometricsUnavailable
        }

        try await evaluate(policy: .deviceOwnerAuthenticationWithBiometrics, context: context, reason: reason)
    }

    private func evaluate(policy: LAPolicy, context: LAContext, reason: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            var didResume = false
            context.evaluatePolicy(policy, localizedReason: reason) { success, evaluateError in
                guard !didResume else { return }
                didResume = true
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: evaluateError ?? SecurityServiceError.biometricsUnavailable)
                }
            }
        }
    }

    func generatePrivateKeyReference(label: String, preferSecureEnclave: Bool) throws -> (reference: String, publicKey: String) {
        if preferSecureEnclave, let key = try? generateSecureEnclaveKey(label: label) {
            let publicKeyData = try exportPublicKey(from: key)
            return (reference: "se:\(label)", publicKey: publicKeyData.base64EncodedString())
        }

        let privateKey = P256.Signing.PrivateKey()
        let keyData = privateKey.rawRepresentation
        let keyRef = "sw:\(label)"
        try store(keyData, for: keyRef)
        let publicKey = privateKey.publicKey.rawRepresentation.base64EncodedString()
        return (reference: keyRef, publicKey: publicKey)
    }

    func sign(data: Data, privateKeyReference: String) throws -> Data {
        if privateKeyReference.hasPrefix("se:") {
            guard let key = try readSecureEnclaveKey(label: String(privateKeyReference.dropFirst(3))) else {
                throw SecurityServiceError.keyNotFound
            }
            var error: Unmanaged<CFError>?
            guard let signature = SecKeyCreateSignature(
                key,
                .ecdsaSignatureMessageX962SHA256,
                data as CFData,
                &error
            ) as Data? else {
                throw error?.takeRetainedValue() ?? SecurityServiceError.signingFailed
            }
            return signature
        }

        guard let raw = try read(for: privateKeyReference) else {
            throw SecurityServiceError.keyNotFound
        }

        let privateKey = try P256.Signing.PrivateKey(rawRepresentation: raw)
        let signature = try privateKey.signature(for: data)
        return signature.derRepresentation
    }

    func store(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let search: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]
            let update: [String: Any] = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(search as CFDictionary, update as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw SecurityServiceError.keychainError(updateStatus)
            }
            return
        }

        guard status == errSecSuccess else {
            throw SecurityServiceError.keychainError(status)
        }
    }

    func read(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw SecurityServiceError.keychainError(status)
        }

        return item as? Data
    }

    private func generateSecureEnclaveKey(label: String) throws -> SecKey {
        #if targetEnvironment(simulator)
        throw SecurityServiceError.keyGenerationFailed
        #else
        let tag = "com.coldvault.se.\(label)".data(using: .utf8)!
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage],
            nil
        )

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag,
                kSecAttrAccessControl as String: access as Any
            ]
        ]

        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error?.takeRetainedValue() ?? SecurityServiceError.keyGenerationFailed
        }
        return key
        #endif
    }

    private func readSecureEnclaveKey(label: String) throws -> SecKey? {
        let tag = "com.coldvault.se.\(label)".data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw SecurityServiceError.keychainError(status)
        }
        return item as! SecKey
    }

    private func exportPublicKey(from privateKey: SecKey) throws -> Data {
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw SecurityServiceError.keyGenerationFailed
        }
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            throw error?.takeRetainedValue() ?? SecurityServiceError.keyGenerationFailed
        }
        return data
    }
}
