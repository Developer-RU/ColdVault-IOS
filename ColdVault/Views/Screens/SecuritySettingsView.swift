import SwiftUI
import UniformTypeIdentifiers

private struct SettingsRow<Content: View>: View {
    let titleKey: LocalizedStringKey
    @ViewBuilder var control: Content

    init(_ titleKey: LocalizedStringKey, @ViewBuilder control: () -> Content) {
        self.titleKey = titleKey
        self.control = control()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(titleKey)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            control
                .frame(maxWidth: 190, alignment: .trailing)
        }
    }
}

struct SecuritySettingsView: View {
    private enum Field: Hashable {
        case passphrase
        case encryptedPayload
    }

    @EnvironmentObject private var viewModel: ColdVaultViewModel
    @Environment(\.locale) private var locale

    @State private var backupJSON = ""
    @State private var backupPassphrase = ""
    @State private var encryptedBackupInput = ""
    @State private var isImporterPresented = false
    @State private var deferredImporterRequest = false
    @FocusState private var focusedField: Field?

    private var isKeyboardActive: Bool {
        focusedField != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                GlassCard(title: "settings.security") {
                    VStack(spacing: 8) {
                        SettingsRow("settings.biometric_lock") {
                            Toggle("", isOn: Binding(
                                get: { viewModel.settings.requireBiometricOnLaunch },
                                set: { value in
                                    viewModel.setBiometricLock(enabled: value)
                                }
                            ))
                            .labelsHidden()
                        }

                        SettingsRow("settings.secure_enclave") {
                            Toggle("", isOn: Binding(
                                get: { viewModel.settings.useSecureEnclaveWhenAvailable },
                                set: { value in
                                    viewModel.setSecureEnclave(enabled: value)
                                }
                            ))
                            .labelsHidden()
                        }

                        SettingsRow("settings.network") {
                            Picker("", selection: Binding(
                                get: { viewModel.settings.selectedNetwork },
                                set: { value in
                                    viewModel.setSelectedNetwork(value)
                                }
                            )) {
                                ForEach(BlockchainNetwork.all) { network in
                                    HStack(spacing: 8) {
                                        CurrencyIconView(network: network, size: 18)
                                        Text(network.localizedDisplayName(locale: locale))
                                    }
                                    .tag(network)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }

                        SettingsRow("settings.theme") {
                            Picker("", selection: Binding(
                                get: { viewModel.settings.appTheme },
                                set: { value in
                                    viewModel.setTheme(value)
                                }
                            )) {
                                ForEach(AppTheme.allCases) { theme in
                                    Text(LocalizedStringKey(theme.titleKey)).tag(theme)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }

                        SettingsRow("settings.language") {
                            Picker("", selection: Binding(
                                get: { viewModel.settings.appLanguage },
                                set: { value in
                                    viewModel.setLanguage(value)
                                }
                            )) {
                                ForEach(AppLanguage.allCases) { language in
                                    Text(LocalizedStringKey(language.titleKey)).tag(language)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }
                    }
                }
                .cvCardEntrance(delay: 0.02)

                GlassCard(title: "settings.backup") {
                    VStack(alignment: .leading, spacing: 10) {
                        SettingsRow("settings.backup.passphrase") {
                            SecureField("", text: $backupPassphrase)
                                .focused($focusedField, equals: .passphrase)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .cvInputField()
                        }

                        SettingsRow("settings.backup.create_encrypted") {
                            Button("common.run") {
                                backupJSON = viewModel.createEncryptedBackup(passphrase: backupPassphrase)
                            }
                            .cvPrimaryAction()
                        }

                        SettingsRow("settings.backup.export") {
                            if !backupJSON.isEmpty {
                                ShareLink(item: backupJSON) {
                                    Text("common.run")
                                }
                                .cvSecondaryAction()
                            } else {
                                Button("common.run") {}
                                    .cvSecondaryAction()
                                    .disabled(true)
                            }
                        }

                        SettingsRow("settings.backup.import_title") {
                            TextEditor(text: $encryptedBackupInput)
                                .focused($focusedField, equals: .encryptedPayload)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.caption.monospaced())
                                .frame(width: 180)
                                .frame(minHeight: 120)
                                .cvInputField()
                        }

                        SettingsRow("settings.backup.import_file") {
                            Button("common.run") {
                                if isKeyboardActive {
                                    deferredImporterRequest = true
                                    focusedField = nil
                                } else {
                                    isImporterPresented = true
                                }
                            }
                            .cvSecondaryAction()
                            .disabled(isImporterPresented)
                        }

                        SettingsRow("settings.backup.restore") {
                            Button("common.run") {
                                focusedField = nil
                                viewModel.restoreEncryptedBackup(
                                    encryptedPayload: encryptedBackupInput,
                                    passphrase: backupPassphrase
                                )
                            }
                            .cvPrimaryAction()
                            .disabled(isKeyboardActive || encryptedBackupInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .cvCardEntrance(delay: 0.1)

                GlassCard(title: "settings.logs") {
                    VStack(spacing: 8) {
                        SettingsRow("settings.logs.auto_clear") {
                            Toggle("", isOn: Binding(
                                get: { viewModel.settings.autoClearLogsOnLaunch },
                                set: { value in
                                    viewModel.setAutoClearLogsOnLaunch(enabled: value)
                                }
                            ))
                            .labelsHidden()
                        }

                        SettingsRow("settings.logs.clear_now") {
                            Button("common.delete") {
                                viewModel.clearEvents()
                            }
                            .cvDestructiveAction()
                            .disabled(viewModel.events.isEmpty)
                        }
                    }
                }
                .cvCardEntrance(delay: 0.16)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("common.done") {
                    focusedField = nil
                }
            }
        }
        .onChange(of: focusedField) { value in
            guard value == nil, deferredImporterRequest, !isImporterPresented else {
                return
            }
            deferredImporterRequest = false
            DispatchQueue.main.async {
                isImporterPresented = true
            }
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.plainText, .json, .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                guard let url = urls.first else { return }
                let granted = url.startAccessingSecurityScopedResource()
                defer {
                    if granted {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                if let data = try? Data(contentsOf: url),
                   let text = String(data: data, encoding: .utf8) {
                    encryptedBackupInput = text
                }
            case .failure:
                break
            }
        }
    }
}
