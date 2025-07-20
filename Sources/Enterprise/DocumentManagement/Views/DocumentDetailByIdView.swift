//
//  DocumentDetailByIdView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

/// Document Detail View accessed by ID
/// Used when navigating directly to a document without having the model loaded
struct DocumentDetailByIdView: View {
    let documentId: String
    @StateObject private var viewModel = DocumentViewModel()
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading document...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let document = viewModel.documents.first(where: { $0.id.uuidString == documentId }) {
                DocumentDetailView(document: document, viewModel: viewModel)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.questionmark")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Document Not Found")
                        .font(.title2.weight(.semibold))
                    
                    Text("The requested document could not be found.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .onAppear {
            loadDocument()
        }
    }
    
    private func loadDocument() {
        Task {
            await viewModel.loadDocuments()
            isLoading = false
        }
    }
}

/// Document Version History View accessed by ID
struct DocumentVersionHistoryByIdView: View {
    let documentId: String
    @StateObject private var viewModel = DocumentViewModel()
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading document...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let document = viewModel.documents.first(where: { $0.id.uuidString == documentId }) {
                DocumentVersionHistoryView(document: document)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.questionmark")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Document Not Found")
                        .font(.title2.weight(.semibold))
                    
                    Text("The requested document could not be found.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .onAppear {
            loadDocument()
        }
    }
    
    private func loadDocument() {
        Task {
            await viewModel.loadDocuments()
            isLoading = false
        }
    }
}

// MARK: - Preview

#Preview {
    DocumentDetailByIdView(documentId: "sample-document-id")
        .preferredColorScheme(.light)
}

#Preview("Version History") {
    DocumentVersionHistoryByIdView(documentId: "sample-document-id")
        .preferredColorScheme(.light)
}
