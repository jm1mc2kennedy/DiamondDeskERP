import SwiftUI

struct DocumentCreationView: View {
    @ObservedObject var viewModel: DocumentViewModel
    @State private var title: String = ""
    @State private var category: String = ""
    @State private var versionText: String = "1"
    @State private var assetURLString: String = ""
    @State private var createdBy: String = ""
    @State private var showError = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Document Info")) {
                    TextField("Title", text: $title)
                    TextField("Category", text: $category)
                    TextField("Version", text: $versionText)
                        .keyboardType(.numberPad)
                    TextField("Asset URL", text: $assetURLString)
                    TextField("Created By", text: $createdBy)
                }
            }
            .navigationTitle("New Document")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    Task {
                        let version = Int(versionText) ?? 1
                        let url = URL(string: assetURLString)
                        let doc = Document(
                            title: title,
                            category: category.isEmpty ? nil : category,
                            version: version,
                            assetURL: url,
                            createdBy: createdBy.isEmpty ? "" : createdBy
                        )
                        await viewModel.saveDocument(doc)
                        if viewModel.errorMessage != nil {
                            showError = true
                        } else {
                            dismiss()
                        }
                    }
                }
                .disabled(title.isEmpty || createdBy.isEmpty)
            )
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { showError = false }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }
}

#Preview {
    DocumentCreationView(viewModel: DocumentViewModel())
}
