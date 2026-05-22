import SwiftUI

@main
struct ColdVaultApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: ColdVaultViewModel

    init() {
        let security = SecurityService()
        let walletService = WalletService(securityService: security)
        _viewModel = StateObject(
            wrappedValue: ColdVaultViewModel(
                securityService: security,
                qrService: QRService(),
                walletService: walletService,
                backupService: BackupService()
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
                .environment(\.locale, viewModel.settings.appLanguage.locale)
                .preferredColorScheme(viewModel.settings.appTheme.colorScheme)
                .task {
                    viewModel.bootstrap()
                    await viewModel.authenticateIfNeeded()
                }
                .onChange(of: scenePhase) { phase in
                    Task {
                        await viewModel.handleScenePhase(phase)
                    }
                }
        }
    }
}
