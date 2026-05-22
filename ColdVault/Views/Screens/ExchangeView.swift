import SwiftUI

struct ExchangeView: View {
    @Environment(\.locale) private var locale
    @EnvironmentObject private var viewModel: ColdVaultViewModel
    @State private var showScanner = false
    @State private var showFullScreenQR = false

    private var sourceDevice: String {
        #if targetEnvironment(simulator)
        return "Simulator"
        #else
        return "iPhone"
        #endif
    }

    private var qrImage: UIImage? {
        viewModel.qrService.makeQRCode(from: viewModel.outgoingPayload)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                GlassCard(title: "exchange.send_qr") {
                    VStack(spacing: 10) {
                        if let wallet = viewModel.selectedWallet {
                            HStack(spacing: 10) {
                                CurrencyIconView(network: wallet.network, size: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(wallet.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text(wallet.network.localizedDisplayName(locale: locale))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }

                        Button("exchange.prepare") {
                            viewModel.prepareWalletExchangePayload(sourceDevice: sourceDevice)
                        }
                        .cvPrimaryActionFullWidth()

                        QRCodeImageView(image: qrImage)
                            .padding(8)
                            .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                            )
                            .overlay(alignment: .topTrailing) {
                                if qrImage != nil {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.caption.weight(.bold))
                                        .padding(8)
                                        .background(Color.black.opacity(0.5), in: Circle())
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.8)
                                        )
                                        .padding(8)
                                }
                            }
                            .scaleEffect(viewModel.outgoingPayload.isEmpty ? 0.96 : 1)
                            .opacity(viewModel.outgoingPayload.isEmpty ? 0.82 : 1)
                            .animation(.easeInOut(duration: 0.25), value: viewModel.outgoingPayload)
                            .onTapGesture {
                                guard qrImage != nil else { return }
                                showFullScreenQR = true
                            }
                    }
                }
                .cvCardEntrance(delay: 0.02)

                GlassCard(title: "exchange.import_scan") {
                    VStack(alignment: .leading, spacing: 10) {
                        Button("exchange.scan_qr") {
                            showScanner = true
                        }
                        .cvSecondaryActionFullWidth()

                        Text(viewModel.lastExchangeMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .cvCardEntrance(delay: 0.1)
            }
            .padding()
        }
        .sheet(isPresented: $showScanner) {
            QRScannerView { code in
                viewModel.importPayload(rawValue: code)
                showScanner = false
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showFullScreenQR) {
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()

                VStack(spacing: 16) {
                    Spacer(minLength: 0)

                    if let image = qrImage {
                        QRCodeImageView(image: image)
                            .frame(maxWidth: 520)
                            .padding(14)
                            .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 0)
                }

                Button {
                    showFullScreenQR = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.bold))
                        .padding(12)
                        .background(Color.white.opacity(0.14), in: Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.32), lineWidth: 0.8)
                        )
                }
                .padding(.top, 18)
                .padding(.trailing, 18)
            }
        }
    }
}
