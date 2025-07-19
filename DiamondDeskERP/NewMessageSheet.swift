import SwiftUI

struct NewMessageSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MessageViewModel
    @State private var messageText = ""
    @State private var author = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Your message", text: $messageText)
                TextField("Your name", text: $author)
            }
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        if !messageText.isEmpty {
                            viewModel.addMessage(title: messageText, author: author.isEmpty ? "Anonymous" : author)
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
