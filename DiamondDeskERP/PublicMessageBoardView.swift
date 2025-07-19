import SwiftUI

struct PublicMessageBoardView: View {
    @StateObject private var viewModel = MessageViewModel()
    @State private var filterAuthor = ""
    @State private var showNewMessageSheet = false

    var filteredMessages: [PublicMessage] {
        if filterAuthor.isEmpty {
            return viewModel.messages
        } else {
            return viewModel.messages.filter { $0.author.lowercased().contains(filterAuthor.lowercased()) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                TextField("Filter by author name", text: $filterAuthor)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.leading, .trailing])
                List {
                    ForEach(filteredMessages) { message in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(message.title)
                                .font(.headline)
                            Text("— \(message.author)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let authorID = message.authorID {
                                Text("iCloud: \(authorID)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
                .refreshable {
                    viewModel.fetchMessages()
                }

                Button("New Message") {
                    showNewMessageSheet = true
                }
                .padding()
                .sheet(isPresented: $showNewMessageSheet) {
                    NewMessageSheet(viewModel: viewModel)
                }
            }
            .navigationTitle("Public Message Board")
            .onAppear { viewModel.fetchMessages() }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let message = viewModel.messages[index]
            viewModel.deleteMessageIfAuthorized(message)
        }
    }
}
