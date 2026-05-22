import SwiftUI

struct TransactionView: View {
    @Environment(\.locale) private var locale
    @EnvironmentObject private var viewModel: ColdVaultViewModel

    @State private var toAddress: String = ""
    @State private var amountText: String = "1.00"
    @State private var memo: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                GlassCard(title: "transaction.create_and_sign") {
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
                            .padding(.bottom, 2)
                        }

                        TextField("transaction.to_address", text: $toAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .cvInputField()

                        TextField("transaction.amount", text: $amountText)
                            .keyboardType(.decimalPad)
                            .cvInputField()

                        TextField("transaction.comment", text: $memo)
                            .cvInputField()

                        Button("transaction.sign_offline") {
                            let amount = Decimal(string: amountText) ?? 0
                            viewModel.signTransaction(to: toAddress, amount: amount, memo: memo)
                        }
                        .cvPrimaryActionFullWidth()
                    }
                }
                .cvCardEntrance(delay: 0.02)

                GlassCard(title: "transaction.export") {
                    if let wallet = viewModel.selectedWallet {
                        HStack(spacing: 8) {
                            CurrencyIconView(network: wallet.network, size: 20)
                            Text(wallet.network.localizedDisplayName(locale: locale))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }

                    if viewModel.outgoingPayload.isEmpty {
                        Text("transaction.sign_first")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    } else {
                        Text(viewModel.outgoingPayload)
                            .font(.footnote.monospaced())
                            .lineLimit(6)
                            .textSelection(.enabled)
                            .padding(10)
                            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.6)
                            )
                    }
                }
                .cvCardEntrance(delay: 0.1)

            }
            .padding()
        }
    }
}
