import SwiftUI

struct ClientListView: View {
    @StateObject private var viewModel = ClientViewModel()
    @Environment(\.currentUser) private var currentUser

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading clients...")
                } else if let error = viewModel.error {
                    VStack {
                        Text("Error loading clients")
                        Text(error.localizedDescription).font(.caption)
                    }
                } else if viewModel.clients.isEmpty {
                    Text("No clients found.")
                } else {
                    List(viewModel.clients) { client in
                        ClientRow(client: client)
                    }
                }
            }
            .navigationTitle("My Clients")
            .onAppear {
                if let user = currentUser {
                    viewModel.fetchClients(for: user)
                }
            }
        }
    }
}

struct ClientRow: View {
    let client: ClientModel

    var body: some View {
        VStack(alignment: .leading) {
            Text(client.guestName).font(.headline)
            if let partner = client.partnerName, !partner.isEmpty {
                Text("Partner: \(partner)").font(.subheadline)
            }
            HStack {
                Text("Store: \(client.preferredStoreCode)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let lastInteraction = client.lastInteraction {
                    Text("Last Interaction: \(lastInteraction, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct ClientListView_Previews: PreviewProvider {
    static var previews: some View {
        ClientListView()
    }
}
