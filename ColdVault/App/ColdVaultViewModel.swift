import Foundation
import LocalAuthentication
import SwiftUI
import UIKit

@MainActor
/// Central MVVM state and orchestration layer for wallets, signing, QR exchange, backups, and settings.
final class ColdVaultViewModel: ObservableObject {
    private struct BackupSnapshot: Codable {
        let createdAt: Date
        let settings: AppSettings
        let wallets: [Wallet]
        let events: [SecurityEvent]
    }

    @Published var wallets: [Wallet] = []
    @Published var events: [SecurityEvent] = []
    @Published var settings = AppSettings()
    @Published var selectedWalletID: Wallet.ID?
    @Published var outgoingPayload: String = ""
    @Published var lastExchangeMessage: String = ""
    @Published var isBiometricUnlocked: Bool = false
    @Published var errorMessage: String?
    private var isAuthenticatingBiometrics = false

    private let settingsKey = "coldvault.settings"
    private let eventsKey = "coldvault.events"
    private let maxEventsCount = 200
    private let supportedAppLocales = [Locale(identifier: "ru"), Locale(identifier: "en")]
    private var lastExchangeMessageKey = "vm.exchange.status.waiting"
    private var lastExchangeMessageArguments: [String] = []

    let securityService: SecurityServiceProtocol
    let qrService: QRServiceProtocol
    let walletService: WalletServiceProtocol
    let backupService: BackupServiceProtocol

    init(
        securityService: SecurityServiceProtocol,
        qrService: QRServiceProtocol,
        walletService: WalletServiceProtocol,
        backupService: BackupServiceProtocol
    ) {
        self.securityService = securityService
        self.qrService = qrService
        self.walletService = walletService
        self.backupService = backupService
        self.lastExchangeMessage = loc("vm.exchange.status.waiting")
    }

    private var activeLocale: Locale {
        let locale = settings.appLanguage.locale
        return locale.identifier.isEmpty ? Locale.current : locale
    }

    private var localizationBundle: Bundle {
        if let code = settings.appLanguage.localeIdentifier,
           let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }

    private func loc(_ key: String) -> String {
        NSLocalizedString(key, bundle: localizationBundle, comment: "")
    }

    private func locf(_ key: String, _ args: CVarArg...) -> String {
        String(format: loc(key), locale: activeLocale, arguments: args)
    }

    private func setExchangeStatus(_ key: String, arguments: [String] = []) {
        lastExchangeMessageKey = key
        lastExchangeMessageArguments = arguments

        guard !arguments.isEmpty else {
            lastExchangeMessage = loc(key)
            return
        }

        let format = loc(key)
        let args: [CVarArg] = arguments
        lastExchangeMessage = String(format: format, locale: activeLocale, arguments: args)
    }

    var selectedWallet: Wallet? {
        wallets.first(where: { $0.id == selectedWalletID })
    }

    func bootstrap() {
        loadSettings()
        setExchangeStatus(lastExchangeMessageKey, arguments: lastExchangeMessageArguments)

        #if targetEnvironment(simulator)
        settings.requireBiometricOnLaunch = false
        saveSettings()
        #endif

        events = loadEvents()
        if settings.autoClearLogsOnLaunch, !events.isEmpty {
            events.removeAll()
            saveEvents()
        }
        wallets = walletService.loadWallets()
        normalizeLocalizedNamesIfNeeded()

        // Migration: remove legacy demo wallets from persisted storage.
        let filteredWallets = wallets.filter { !$0.isDemo }
        if filteredWallets.count != wallets.count {
            wallets = filteredWallets
            walletService.saveWallets(wallets)
        }

        selectedWalletID = selectedWalletID ?? wallets.first?.id
    }

    func authenticateIfNeeded() async {
        #if targetEnvironment(simulator)
        isBiometricUnlocked = true
        return
        #endif

        guard settings.requireBiometricOnLaunch else {
            isBiometricUnlocked = true
            return
        }

        guard !isBiometricUnlocked, !isAuthenticatingBiometrics else {
            return
        }

        isAuthenticatingBiometrics = true
        defer { isAuthenticatingBiometrics = false }

        do {
            try await securityService.authenticateWithBiometrics(reason: loc("vm.auth.unlock_reason"))
            isBiometricUnlocked = true
            addEvent(.biometricSuccess, detailKey: "vm.event.access_confirmed")
        } catch {
            isBiometricUnlocked = false
            if !isIgnorableBiometricError(error) {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func isIgnorableBiometricError(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == LAError.errorDomain else {
            return false
        }

        return nsError.code == LAError.userCancel.rawValue
            || nsError.code == LAError.appCancel.rawValue
            || nsError.code == LAError.systemCancel.rawValue
            || nsError.code == LAError.notInteractive.rawValue
    }

    func handleScenePhase(_ phase: ScenePhase) async {
        #if targetEnvironment(simulator)
        if phase == .active {
            isBiometricUnlocked = true
        }
        return
        #endif

        switch phase {
        case .background, .inactive:
            if settings.requireBiometricOnLaunch {
                isBiometricUnlocked = false
            }
        case .active:
            if settings.requireBiometricOnLaunch, !isBiometricUnlocked {
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                await authenticateIfNeeded()
            }
        @unknown default:
            break
        }
    }

    func createWallet(name: String) {
        do {
            let wallet = try walletService.createWallet(
                name: name,
                network: settings.selectedNetwork,
                preferSecureEnclave: settings.useSecureEnclaveWhenAvailable
            )
            wallets.insert(wallet, at: 0)
            walletService.saveWallets(wallets)
            selectedWalletID = wallet.id
            addEvent(.keyCreated, detailKey: "vm.event.wallet_created", arguments: [wallet.name])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createAllModernWalletsForIPhone() {
        #if targetEnvironment(simulator)
        errorMessage = loc("vm.error.modern_wallets_iphone_only")
        return
        #endif

        guard UIDevice.current.userInterfaceIdiom == .phone else {
            errorMessage = loc("vm.error.feature_iphone_only")
            return
        }

        let existingNetworks = Set(wallets.map { $0.network.id })
        var createdWallets: [Wallet] = []

        for network in BlockchainNetwork.modernMainnets where !existingNetworks.contains(network.id) {
            do {
                let wallet = try walletService.createWallet(
                    name: network.localizedDisplayName(locale: activeLocale),
                    network: network,
                    preferSecureEnclave: settings.useSecureEnclaveWhenAvailable
                )
                createdWallets.append(wallet)
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }

        guard !createdWallets.isEmpty else {
            errorMessage = loc("vm.error.modern_wallets_all_created")
            return
        }

        wallets.insert(contentsOf: createdWallets, at: 0)
        walletService.saveWallets(wallets)
        selectedWalletID = selectedWalletID ?? wallets.first?.id
        addEvent(.keyCreated, detailKey: "vm.event.modern_wallets_created", arguments: ["\(createdWallets.count)"])
    }

    func deleteWallet(id: Wallet.ID) {
        guard let index = wallets.firstIndex(where: { $0.id == id }) else {
            return
        }

        let removed = wallets.remove(at: index)
        walletService.saveWallets(wallets)

        if selectedWalletID == removed.id {
            selectedWalletID = wallets.first?.id
        }

        addEvent(.walletDeleted, detailKey: "vm.event.wallet_deleted", arguments: [removed.name])
    }

    func signTransaction(to toAddress: String, amount: Decimal, memo: String) {
        guard let wallet = selectedWallet else {
            errorMessage = loc("vm.error.select_wallet")
            return
        }

        do {
            let draft = TransactionDraft(
                fromAddress: wallet.address,
                toAddress: toAddress,
                amount: amount,
                memo: memo
            )
            let signed = try walletService.signTransaction(draft, with: wallet)
            outgoingPayload = try walletService.exportSignedTransaction(signed, wallet: wallet)
            let amountString = NSDecimalNumber(decimal: amount).stringValue
            addEvent(.signatureDone, detailKey: "vm.event.transaction_signed", arguments: [amountString])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func prepareWalletExchangePayload(sourceDevice: String) {
        guard let wallet = selectedWallet else {
            errorMessage = loc("vm.error.no_selected_wallet")
            return
        }

        let payload = ExchangePayload(
            kind: "wallet_share",
            body: wallet.address,
            sourceDevice: sourceDevice,
            createdAt: .now,
            correlationID: nil
        )

        guard
            let data = try? JSONEncoder().encode(payload),
            let raw = String(data: data, encoding: .utf8)
        else {
            errorMessage = loc("vm.error.payload_prepare_failed")
            return
        }

        outgoingPayload = raw
        addEvent(.dataSent, detailKey: "vm.event.qr_payload_sent")
        setExchangeStatus("vm.exchange.status.qr_ready")
    }

    func importPayload(rawValue: String) {
        guard let payload = qrService.decodePayload(from: rawValue) else {
            errorMessage = loc("vm.error.invalid_qr_payload")
            return
        }

        addEvent(.dataReceived, detailKey: "vm.event.payload_received_type", arguments: [payload.kind])
        setExchangeStatus("vm.exchange.status.success", arguments: [payload.sourceDevice])
    }

    func setBiometricLock(enabled: Bool) {
        #if targetEnvironment(simulator)
        settings.requireBiometricOnLaunch = false
        saveSettings()
        return
        #endif

        settings.requireBiometricOnLaunch = enabled
        saveSettings()
    }

    func setSecureEnclave(enabled: Bool) {
        settings.useSecureEnclaveWhenAvailable = enabled
        saveSettings()
    }

    func setSelectedNetwork(_ network: BlockchainNetwork) {
        settings.selectedNetwork = network
        saveSettings()
    }

    func setTheme(_ theme: AppTheme) {
        settings.appTheme = theme
        saveSettings()
    }

    func setLanguage(_ language: AppLanguage) {
        settings.appLanguage = language
        normalizeLocalizedNamesIfNeeded()
        setExchangeStatus(lastExchangeMessageKey, arguments: lastExchangeMessageArguments)
        saveSettings()
    }

    func setAutoClearLogsOnLaunch(enabled: Bool) {
        settings.autoClearLogsOnLaunch = enabled
        saveSettings()
    }

    func clearEvents() {
        events.removeAll()
        saveEvents()
    }

    func createEncryptedBackup(passphrase: String) -> String {
        let backup = BackupSnapshot(createdAt: .now, settings: settings, wallets: wallets, events: events)
        do {
            let data = try JSONEncoder().encode(backup)
            let encrypted = try backupService.encryptBackup(plainData: data, passphrase: passphrase)
            addEvent(.backupCreated, detailKey: "vm.event.backup_created")
            return encrypted
        } catch {
            errorMessage = error.localizedDescription
            return ""
        }
    }

    func restoreEncryptedBackup(encryptedPayload: String, passphrase: String) {
        do {
            let decrypted = try backupService.decryptBackup(encryptedString: encryptedPayload, passphrase: passphrase)
            let snapshot = try JSONDecoder().decode(BackupSnapshot.self, from: decrypted)

            settings = snapshot.settings
            wallets = snapshot.wallets.filter { !$0.isDemo }
            events = Array(snapshot.events.prefix(maxEventsCount))
            selectedWalletID = wallets.first?.id

            saveSettings()
            walletService.saveWallets(wallets)
            saveEvents()

            addEvent(.dataReceived, detailKey: "vm.event.backup_restored")
        } catch {
            errorMessage = locf("vm.error.backup_restore_failed", error.localizedDescription)
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func addEvent(_ type: SecurityEventType, detailKey: String, arguments: [String] = []) {
        let event = SecurityEvent(type: type, detailKey: detailKey, detailArguments: arguments)
        events.insert(event, at: 0)
        if events.count > maxEventsCount {
            events.removeSubrange(maxEventsCount...)
        }
        saveEvents()
    }

    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: settingsKey) else {
            return
        }
        if let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        }
    }

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    private func loadEvents() -> [SecurityEvent] {
        guard let data = UserDefaults.standard.data(forKey: eventsKey) else {
            return []
        }
        let decoded = (try? JSONDecoder().decode([SecurityEvent].self, from: data)) ?? []
        let migrated = decoded.map { $0.migratedIfNeeded() }
        let didMigrate = zip(decoded, migrated).contains { old, new in
            old.detailKey != new.detailKey || old.detailArguments != new.detailArguments || old.detail != new.detail
        }

        if didMigrate,
           let migratedData = try? JSONEncoder().encode(migrated) {
            UserDefaults.standard.set(migratedData, forKey: eventsKey)
        }

        return Array(migrated.prefix(maxEventsCount))
    }

    private func saveEvents() {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: eventsKey)
        }
    }

    private func normalizeLocalizedNamesIfNeeded() {
        let mapping = makeNetworkNameMapping(targetLocale: activeLocale)

        var walletsChanged = false
        var updatedWallets = wallets
        for index in updatedWallets.indices {
            let currentName = updatedWallets[index].name
            if let normalized = mapping[currentName], normalized != currentName {
                updatedWallets[index].name = normalized
                walletsChanged = true
            }
        }

        if walletsChanged {
            wallets = updatedWallets
            walletService.saveWallets(wallets)
        }

        var eventsChanged = false
        let updatedEvents: [SecurityEvent] = events.map { event in
            guard let detailKey = event.detailKey, !event.detailArguments.isEmpty else {
                return event
            }

            let mappedArgs = event.detailArguments.map { argument in
                mapping[argument] ?? argument
            }

            if mappedArgs != event.detailArguments {
                eventsChanged = true
                return SecurityEvent(
                    id: event.id,
                    type: event.type,
                    detailKey: detailKey,
                    detailArguments: mappedArgs,
                    timestamp: event.timestamp
                )
            }

            return event
        }

        if eventsChanged {
            events = updatedEvents
            saveEvents()
        }
    }

    private func makeNetworkNameMapping(targetLocale: Locale) -> [String: String] {
        var mapping: [String: String] = [:]

        for network in BlockchainNetwork.all {
            let target = network.localizedDisplayName(locale: targetLocale)

            for locale in supportedAppLocales {
                let candidate = network.localizedDisplayName(locale: locale)
                mapping[candidate] = target
            }
        }

        return mapping
    }
}
