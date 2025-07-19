// ClientListView.swift
// Diamond Desk ERP

import SwiftUI

struct ClientListView: View {
    @StateObject private var viewModel: ClientViewModel
    
    init(userRef: String) {
        _viewModel = StateObject(wrappedValue: ClientViewModel(userRef: userRef))
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.clients) { client in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(client.guestName)
                            .font(.headline)
                        Text("Account #: \(client.guestAcctNumber)")
                            .font(.subheadline).foregroundColor(.secondary)
                        if let followUp = client.followUpDate {
                            Text("Follow-up: \(followUp, formatter: itemFormatter)")
                                .font(.caption)
                        }
                    }
                    .padding(6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .listStyle(.plain)
            .navigationTitle("My Clients")
            .refreshable {
                await viewModel.fetchAssignedClients()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    ClientListView(userRef: "demo-user-id")
}
