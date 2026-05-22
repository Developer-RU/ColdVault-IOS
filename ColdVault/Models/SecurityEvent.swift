import Foundation

/// Normalized set of security-related event categories shown in the event log.
enum SecurityEventType: String, Codable {
    case keyCreated = "ключ создан"
    case walletDeleted = "кошелек удален"
    case dataSent = "данные отправлены"
    case dataReceived = "данные получены"
    case signatureDone = "подпись выполнена"
    case biometricSuccess = "биометрическая проверка успешна"
    case backupCreated = "резервная копия создана"

    var titleKey: String {
        switch self {
        case .keyCreated:
            return "event.type.key_created"
        case .walletDeleted:
            return "event.type.wallet_deleted"
        case .dataSent:
            return "event.type.data_sent"
        case .dataReceived:
            return "event.type.data_received"
        case .signatureDone:
            return "event.type.signature_done"
        case .biometricSuccess:
            return "event.type.biometric_success"
        case .backupCreated:
            return "event.type.backup_created"
        }
    }
}

/// Stored event item rendered in dashboard/event-history views.
struct SecurityEvent: Identifiable, Codable {
    let id: UUID
    let type: SecurityEventType
    let detail: String
    let detailKey: String?
    let detailArguments: [String]
    let timestamp: Date

    init(id: UUID = UUID(), type: SecurityEventType, detail: String, timestamp: Date = .now) {
        self.id = id
        self.type = type
        self.detail = detail
        self.detailKey = nil
        self.detailArguments = []
        self.timestamp = timestamp
    }

    init(
        id: UUID = UUID(),
        type: SecurityEventType,
        detailKey: String,
        detailArguments: [String] = [],
        timestamp: Date = .now
    ) {
        self.id = id
        self.type = type
        self.detail = ""
        self.detailKey = detailKey
        self.detailArguments = detailArguments
        self.timestamp = timestamp
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case detail
        case detailKey
        case detailArguments
        case timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(SecurityEventType.self, forKey: .type)
        detail = try container.decodeIfPresent(String.self, forKey: .detail) ?? ""
        detailKey = try container.decodeIfPresent(String.self, forKey: .detailKey)
        detailArguments = try container.decodeIfPresent([String].self, forKey: .detailArguments) ?? []
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }

    func localizedDetail(locale: Locale) -> String {
        if let detailKey {
            return formatLocalizedDetail(key: detailKey, arguments: detailArguments, locale: locale)
        }

        if let inferred = inferredTemplate(from: detail) {
            return formatLocalizedDetail(key: inferred.key, arguments: inferred.arguments, locale: locale)
        }

        // Legacy fallback: if raw detail is not mappable (often old Russian plaintext),
        // show at least a localized generic detail by event type.
        if detail.isEmpty || detail.containsCyrillic {
            return formatLocalizedDetail(key: type.titleKey, arguments: [], locale: locale)
        }

        return detail
    }

    func localizedTitle(locale: Locale) -> String {
        let bundle = Bundle.localizedBundle(for: locale)
        return NSLocalizedString(type.titleKey, bundle: bundle, comment: "")
    }

    func migratedIfNeeded() -> SecurityEvent {
        guard detailKey == nil, let inferred = inferredTemplate(from: detail) else {
            return self
        }

        return SecurityEvent(
            id: id,
            type: type,
            detailKey: inferred.key,
            detailArguments: inferred.arguments,
            timestamp: timestamp
        )
    }

    private func formatLocalizedDetail(key: String, arguments: [String], locale: Locale) -> String {
        let bundle = Bundle.localizedBundle(for: locale)
        let format = NSLocalizedString(key, bundle: bundle, comment: "")

        guard !arguments.isEmpty else {
            return format
        }

        let args: [CVarArg] = arguments
        return String(format: format, locale: locale, arguments: args)
    }

    private func inferredTemplate(from value: String) -> (key: String, arguments: [String])? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized == "Доступ подтвержден" || normalized == "Access confirmed" {
            return ("vm.event.access_confirmed", [])
        }
        if normalized == "Отправлен QR payload" || normalized == "Отправлены данные через QR" || normalized == "QR payload sent" || normalized == "QR transfer data sent" {
            return ("vm.event.qr_payload_sent", [])
        }
        if normalized == "Сформирована зашифрованная резервная копия" || normalized == "Encrypted backup created" {
            return ("vm.event.backup_created", [])
        }
        if normalized == "Состояние восстановлено из encrypted backup" || normalized == "Состояние восстановлено из зашифрованной копии" || normalized == "State restored from encrypted backup" {
            return ("vm.event.backup_restored", [])
        }

        if let name = suffix(value: normalized, prefixes: ["Создан кошелек: ", "Создан кошелек ", "Wallet created: "]) {
            return ("vm.event.wallet_created", [name])
        }
        if let count = suffix(value: normalized, prefixes: ["Создано современных кошельков: ", "Modern wallets created: "]) {
            return ("vm.event.modern_wallets_created", [count])
        }
        if let name = suffix(value: normalized, prefixes: ["Удален кошелек: ", "Удален кошелек ", "Wallet deleted: "]) {
            return ("vm.event.wallet_deleted", [name])
        }
        if let amount = suffix(value: normalized, prefixes: ["Подписана транзакция на ", "Transaction signed for "]) {
            return ("vm.event.transaction_signed", [amount])
        }
        if let kind = suffix(value: normalized, prefixes: ["Получен payload типа: ", "Получены данные типа: ", "Received payload type: ", "Received data type: "]) {
            return ("vm.event.payload_received_type", [kind])
        }

        return nil
    }

    private func suffix(value: String, prefixes: [String]) -> String? {
        for prefix in prefixes where value.hasPrefix(prefix) {
            return String(value.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
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

private extension String {
    var containsCyrillic: Bool {
        unicodeScalars.contains { scalar in
            (0x0400...0x04FF).contains(Int(scalar.value))
        }
    }
}
