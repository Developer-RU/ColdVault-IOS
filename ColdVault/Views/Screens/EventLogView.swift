import SwiftUI

struct EventLogView: View {
    @EnvironmentObject private var viewModel: ColdVaultViewModel

    var body: some View {
        List {
            if viewModel.events.isEmpty {
                Text("dashboard.events_empty")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.events) { event in
                    EventRow(event: event)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("dashboard.events.full_title")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.clearEvents()
                } label: {
                    Text("settings.logs.clear_now")
                        .underline(false)
                }
                .padding(.horizontal, 8)
                .buttonStyle(.plain)
                .disabled(viewModel.events.isEmpty)
            }
        }
    }
}
