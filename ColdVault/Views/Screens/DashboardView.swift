import SwiftUI

struct DashboardView: View {
    @Environment(\.locale) private var locale
    @EnvironmentObject private var viewModel: ColdVaultViewModel
    @State private var walletName: String = ""
    @State private var walletForDeletion: Wallet?
    private let eventsPreviewLimit = 5

    private var isDeleteDialogVisible: Bool {
        walletForDeletion != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                GlassCard(title: "dashboard.active_wallet") {
                    if let wallet = viewModel.selectedWallet {
                        HStack(alignment: .top, spacing: 10) {
                            CurrencyIconView(network: wallet.network, size: 34)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(wallet.name)
                                    .font(.title3.weight(.semibold))
                                Text(wallet.network.localizedDisplayName(locale: locale))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(wallet.address)
                                    .font(.footnote.monospaced())
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                                HStack {
                                    Text("dashboard.balance")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(wallet.balance.formatted(.number.precision(.fractionLength(2)))) DMO")
                                        .font(.headline)
                                        .contentTransition(.numericText())
                                }
                            }
                        }
                    } else {
                        Text("dashboard.no_wallets")
                            .foregroundStyle(.secondary)
                    }
                }
                .cvCardEntrance(delay: 0.02)

                GlassCard(title: "dashboard.create_wallet") {
                    HStack {
                        TextField("dashboard.wallet_name", text: $walletName)
                            .textInputAutocapitalization(.words)
                            .cvInputField()

                        Button {
                            let name = walletName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !name.isEmpty else { return }
                            viewModel.createWallet(name: name)
                            walletName = ""
                        } label: {
                            Label("dashboard.create_single", systemImage: "plus")
                                .labelStyle(.iconOnly)
                                .font(.headline.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                        }
                        .cvPrimaryAction()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("settings.network")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(BlockchainNetwork.all) { network in
                                    let isSelected = viewModel.settings.selectedNetwork == network
                                    Button {
                                        withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                                            viewModel.setSelectedNetwork(network)
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            CurrencyIconView(network: network, size: 16)
                                            Text(network.localizedDisplayName(locale: locale))
                                                .font(.caption.weight(.semibold))
                                                .lineLimit(1)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(isSelected ? CVDesign.accent.opacity(0.2) : Color.white.opacity(0.06))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .strokeBorder(isSelected ? CVDesign.accent.opacity(0.9) : Color.white.opacity(0.14), lineWidth: isSelected ? 1.2 : 0.8)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    Button("dashboard.create_modern_all") {
                        viewModel.createAllModernWalletsForIPhone()
                    }
                    .cvPrimaryActionFullWidth()

                    #if targetEnvironment(simulator)
                    Text("dashboard.create_modern_note")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    #endif
                }
                .cvCardEntrance(delay: 0.08)

                GlassCard(title: "dashboard.wallets") {
                    if viewModel.wallets.isEmpty {
                        Text("dashboard.wallets_hint")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.wallets) { wallet in
                            HStack(spacing: 10) {
                                CurrencyIconView(network: wallet.network, size: 28)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(wallet.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text(wallet.network.localizedDisplayName(locale: locale))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(wallet.address)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if viewModel.selectedWalletID == wallet.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.cyan)
                                }

                                Button(role: .destructive) {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                        walletForDeletion = wallet
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption.weight(.semibold))
                                        .padding(6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(Color.red.opacity(0.14))
                                        )
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.red)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(viewModel.selectedWalletID == wallet.id ? CVDesign.accent.opacity(0.12) : .clear)
                            )
                            .animation(.spring(response: 0.26, dampingFraction: 0.82), value: viewModel.selectedWalletID)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    viewModel.selectedWalletID = wallet.id
                                }
                            }
                            if wallet.id != viewModel.wallets.last?.id {
                                Divider().opacity(0.4)
                            }
                        }
                    }
                }
                .cvCardEntrance(delay: 0.14)

                GlassCard(title: "dashboard.events") {
                    if viewModel.events.isEmpty {
                        Text("dashboard.events_empty")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.events.prefix(eventsPreviewLimit)) { event in
                            EventRow(event: event)
                            if event.id != viewModel.events.prefix(eventsPreviewLimit).last?.id {
                                Divider().opacity(0.2)
                            }
                        }

                        NavigationLink {
                            EventLogView()
                        } label: {
                            HStack {
                                Spacer()
                                Text("dashboard.events.view_all")
                                    .font(.footnote.weight(.semibold))
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                .cvCardEntrance(delay: 0.2)
                .animation(.easeInOut(duration: 0.24), value: viewModel.events.count)
            }
            .padding()
            .padding(.bottom, 24)
        }
        .navigationTitle("dashboard.title")
        .overlay {
            if isDeleteDialogVisible {
                ZStack {
                    Rectangle()
                        .fill(.black.opacity(0.24))
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.88)) {
                                walletForDeletion = nil
                            }
                        }

                    VStack(spacing: 14) {
                        Text("dashboard.confirm_delete_wallet_title")
                            .font(.headline)

                        Text("dashboard.confirm_delete_wallet_message")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 10) {
                            Button("common.cancel") {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.88)) {
                                    walletForDeletion = nil
                                }
                            }
                            .cvSecondaryAction()

                            Button("common.delete") {
                                if let wallet = walletForDeletion {
                                    viewModel.deleteWallet(id: wallet.id)
                                }
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.88)) {
                                    walletForDeletion = nil
                                }
                            }
                            .cvDestructiveAction()
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: 330)
                    .background(Color(uiColor: .systemBackground).opacity(0.9), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.24), lineWidth: 0.8)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 18, y: 12)
                    .transition(.scale(scale: 0.93).combined(with: .opacity))
                }
                .zIndex(1)
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isDeleteDialogVisible)
            }
        }
    }
}
