//
//  CreateDocumentView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI
import UniformTypeIdentifiers

/// Create Document View
/// Modern form for uploading and creating new documents
struct CreateDocumentView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDocumentPicker = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.showingUploadProgress {
                    uploadProgressView
                } else {
                    createDocumentForm
                }
            }
            .navigationTitle("New Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Upload") {
                        viewModel.createDocument()
                    }
                    .disabled(!viewModel.isFormValid)
                    .fontWeight(.semibold)
                }
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: allowedContentTypes,
            allowsMultipleSelection: false
        ) { result in
            viewModel.handleFileSelection(result)
        }
    }
    
    // MARK: - Create Document Form
    
    @ViewBuilder
    private var createDocumentForm: some View {
        ScrollView {
            VStack(spacing: 24) {
                // File Selection Section
                fileSelectionSection
                
                // Document Details Section
                documentDetailsSection
                
                // Settings Section
                settingsSection
                
                // Tags Section
                tagsSection
            }
            .padding()
        }
    }
    
    // MARK: - File Selection Section
    
    @ViewBuilder
    private var fileSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select File")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let fileURL = viewModel.selectedFileURL {
                selectedFileView(fileURL)
            } else {
                fileSelectionButton
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var fileSelectionButton: some View {
        Button {
            showingDocumentPicker = true
        } label: {
            VStack(spacing: 16) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                
                VStack(spacing: 4) {
                    Text("Choose File")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    
                    Text("Select a document to upload")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color.accentColor.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func selectedFileView(_ fileURL: URL) -> some View {
        HStack(spacing: 12) {
            // File icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(fileTypeColor(for: fileURL).opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: fileTypeIcon(for: fileURL))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(fileTypeColor(for: fileURL))
            }
            
            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(fileURL.lastPathComponent)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    Text(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(fileURL.mimeType)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Change button
            Button {
                showingDocumentPicker = true
            } label: {
                Text("Change")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Document Details Section
    
    @ViewBuilder
    private var documentDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Document Details")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // Title field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    TextField("Enter document title", text: $viewModel.newDocumentTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Description field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    TextField("Optional description", text: $viewModel.newDocumentDescription, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Settings Section
    
    @ViewBuilder
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // Category picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    Picker("Category", selection: $viewModel.newDocumentCategory) {
                        ForEach(DocumentCategory.allCases, id: \.self) { category in
                            HStack {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 8, height: 8)
                                Text(category.displayName)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Access level picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Access Level")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    Picker("Access Level", selection: $viewModel.newDocumentAccessLevel) {
                        ForEach(DocumentAccessLevel.allCases, id: \.self) { level in
                            HStack {
                                Circle()
                                    .fill(level.color)
                                    .frame(width: 8, height: 8)
                                Text(level.displayName)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Tags Section
    
    @ViewBuilder
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Add tags to help organize and search for this document")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Enter tags separated by commas", text: $viewModel.newDocumentTags)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !viewModel.newDocumentTags.isEmpty {
                    tagsPreview
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var tagsPreview: some View {
        let tags = viewModel.newDocumentTags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if !tags.isEmpty {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], alignment: .leading, spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Upload Progress View
    
    @ViewBuilder
    private var uploadProgressView: some View {
        VStack(spacing: 24) {
            // Progress animation
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: viewModel.uploadProgress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: viewModel.uploadProgress)
                
                Image(systemName: "arrow.up.doc")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 8) {
                Text("Uploading Document")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Please wait while your document is being uploaded...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("\(Int(viewModel.uploadProgress * 100))%")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.accentColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Helper Methods
    
    private var allowedContentTypes: [UTType] {
        [
            .pdf,
            .plainText,
            .rtf,
            .image,
            .video,
            .audio,
            .archive,
            .data,
            UTType(filenameExtension: "doc") ?? .data,
            UTType(filenameExtension: "docx") ?? .data,
            UTType(filenameExtension: "xls") ?? .data,
            UTType(filenameExtension: "xlsx") ?? .data,
            UTType(filenameExtension: "ppt") ?? .data,
            UTType(filenameExtension: "pptx") ?? .data
        ]
    }
    
    private func fileTypeIcon(for url: URL) -> String {
        let fileType = DocumentFileType.from(mimeType: url.mimeType)
        return fileType.systemImage
    }
    
    private func fileTypeColor(for url: URL) -> Color {
        let fileType = DocumentFileType.from(mimeType: url.mimeType)
        return fileType.color
    }
}

// MARK: - Extensions

extension DocumentAccessLevel {
    var displayName: String {
        switch self {
        case .public:
            return "Public"
        case .internal:
            return "Internal"
        case .confidential:
            return "Confidential"
        case .restricted:
            return "Restricted"
        case .topSecret:
            return "Top Secret"
        }
    }
}

extension DocumentFileType {
    static func from(mimeType: String) -> DocumentFileType {
        switch mimeType {
        case "application/pdf":
            return .pdf
        case "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
            return .word
        case "application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":
            return .excel
        case "application/vnd.ms-powerpoint", "application/vnd.openxmlformats-officedocument.presentationml.presentation":
            return .powerpoint
        case "text/plain", "text/markdown":
            return .text
        case let mimeType where mimeType.hasPrefix("image/"):
            return .image
        case let mimeType where mimeType.hasPrefix("video/"):
            return .video
        case let mimeType where mimeType.hasPrefix("audio/"):
            return .audio
        case "application/zip", "application/x-tar", "application/gzip":
            return .archive
        default:
            return .other
        }
    }
}

// MARK: - Preview

#Preview {
    CreateDocumentView(viewModel: DocumentViewModel())
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    CreateDocumentView(viewModel: DocumentViewModel())
        .preferredColorScheme(.dark)
}
