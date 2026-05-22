import SwiftUI

struct RootView: View {
    @EnvironmentObject private var viewModel: ColdVaultViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(uiColor: .secondarySystemBackground),
                    Color(uiColor: .systemBackground),
                    Color.cyan.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(LinearGradient(colors: [.cyan.opacity(0.22), .mint.opacity(0.08)], startPoint: .top, endPoint: .bottom))
                .frame(width: 320, height: 320)
                .offset(x: 150, y: -280)
                .blur(radius: 8)
                .allowsHitTesting(false)

            Circle()
                .fill(LinearGradient(colors: [.indigo.opacity(0.16), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 280, height: 280)
                .offset(x: -170, y: 320)
                .blur(radius: 14)
                .allowsHitTesting(false)

            if viewModel.isBiometricUnlocked {
                TabView {
                    NavigationStack {
                        DashboardView()
                    }
                    .tabItem {
                        Label("tab.wallet", systemImage: "square.grid.2x2.fill")
                    }

                    NavigationStack {
                        TransactionView()
                    }
                    .tabItem {
                        Label("tab.sign", systemImage: "signature")
                    }

                    NavigationStack {
                        ExchangeView()
                    }
                    .tabItem {
                        Label("tab.exchange", systemImage: "qrcode")
                    }

                    NavigationStack {
                        SecuritySettingsView()
                    }
                    .tabItem {
                        Label("tab.settings", systemImage: "lock.shield")
                    }
                }
                .tint(CVDesign.accent)
                .animation(.spring(response: 0.32, dampingFraction: 0.86), value: viewModel.wallets.count)
                .background(Color.clear)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "lock.circle")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(CVDesign.accent)
                    Text("root.locked")
                        .font(.title3.weight(.bold))
                    Button("root.unlock") {
                        Task {
                            await viewModel.authenticateIfNeeded()
                        }
                    }
                    .cvPrimaryAction()
                }
                .padding(34)
                .background(Color(uiColor: .systemBackground).opacity(0.88), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.24), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.16), radius: 22, y: 10)
                .padding()
            }
        }
        .alert(
            "common.error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.clearError() }
            )
        ) {
            Button("common.ok", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
