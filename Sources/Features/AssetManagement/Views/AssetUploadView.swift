import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AssetUploadView: View {
    @StateObject private var viewModel: AssetManagementViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Upload state
    @State private var selectedFiles: [PHPickerResult] = []
    @State private var selectedDocuments: [URL] = []
    @State private var isShowingPhotoPicker = false
    @State private var isShowingDocumentPicker = false
    @State private var isShowingCamera = false
    
    // Form state
    @State private var assetName = ""
    @State private var assetCategory = ""
    @State private var assetTags = ""
    @State private var assetDescription = ""
    @State private var isPublic = false
    @State private var selectedType: AssetType = .document
    
    // Upload progress
    @State private var uploadProgress: [String: Double] = [:]
    @State private var isUploading = false
    @State private var completedUploads: [Asset] = []
    @State private var uploadErrors: [String] = []
    
    let onUploadComplete: ([Asset]) -> Void
    
    init(viewModel: AssetManagementViewModel, onUploadComplete: @escaping ([Asset]) -> Void) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onUploadComplete = onUploadComplete
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Upload Method") {
                    uploadMethodButtons
                }
                
                if hasSelectedFiles {
                    Section("Selected Files") {
                        selectedFilesView
                    }
                    
                    Section("Asset Details") {
                        assetDetailsForm
                    }
                    
                    Section("Upload Options") {
                        uploadOptionsForm
                    }
                    
                    if isUploading {
                        Section("Upload Progress") {
                            uploadProgressView
                        }
                    }
                }
            }
            .navigationTitle("Upload Assets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Upload") {
                        uploadAssets()
                    }
                    .disabled(!canUpload)
                }
            }
            .sheet(isPresented: $isShowingPhotoPicker) {
                PhotoPickerView(selectedFiles: $selectedFiles)
            }
            .sheet(isPresented: $isShowingDocumentPicker) {
                DocumentPickerView(selectedDocuments: $selectedDocuments)
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraView { image in
                    handleCameraImage(image)
                }
            }
            .alert("Upload Error", isPresented: .constant(!uploadErrors.isEmpty)) {
                Button("OK") {
                    uploadErrors.removeAll()
                }
            } message: {
                Text(uploadErrors.joined(separator: "\n"))
            }
        }
    }
    
    // MARK: - Upload Method Buttons
    
    private var uploadMethodButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                UploadMethodButton(
                    title: "Photos",
                    icon: "photo.on.rectangle",
                    color: .blue
                ) {
                    isShowingPhotoPicker = true
                }
                
                UploadMethodButton(
                    title: "Camera",
                    icon: "camera",
                    color: .green
                ) {
                    isShowingCamera = true
                }
            }
            
            HStack(spacing: 12) {
                UploadMethodButton(
                    title: "Files",
                    icon: "doc",
                    color: .orange
                ) {
                    isShowingDocumentPicker = true
                }
                
                UploadMethodButton(
                    title: "Cloud",
                    icon: "icloud",
                    color: .purple
                ) {
                    // Handle cloud import
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Selected Files View
    
    private var selectedFilesView: some View {
        ForEach(selectedFileItems, id: \.id) { item in
            HStack {
                Image(systemName: item.icon)
                    .foregroundColor(item.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let size = item.size {
                        Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let progress = uploadProgress[item.id] {
                    CircularProgressView(progress: progress)
                        .frame(width: 24, height: 24)
                } else {
                    Button(action: { removeFile(id: item.id) }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Asset Details Form
    
    private var assetDetailsForm: some View {
        Group {
            Picker("Type", selection: $selectedType) {
                ForEach(AssetType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            TextField("Asset Name", text: $assetName)
                .textInputAutocapitalization(.words)
            
            TextField("Category", text: $assetCategory)
                .textInputAutocapitalization(.words)
            
            TextField("Tags (comma separated)", text: $assetTags)
                .textInputAutocapitalization(.never)
            
            TextField("Description", text: $assetDescription, axis: .vertical)
                .lineLimit(3...6)
                .textInputAutocapitalization(.sentences)
        }
    }
    
    // MARK: - Upload Options Form
    
    private var uploadOptionsForm: some View {
        Group {
            Toggle("Make Public", isOn: $isPublic)
            
            if isPublic {
                Text("Public assets can be viewed by anyone with access to the system")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Upload Progress View
    
    private var uploadProgressView: some View {
        VStack(spacing: 12) {
            ForEach(selectedFileItems, id: \.id) { item in
                if let progress = uploadProgress[item.id] {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.name)
                                .font(.subheadline)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
            }
            
            HStack {
                Text("Overall Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(completedUploads.count)/\(selectedFileItems.count)")
                    .font(.caption)
            }
            
            ProgressView(value: overallProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Computed Properties
    
    private var hasSelectedFiles: Bool {
        !selectedFiles.isEmpty || !selectedDocuments.isEmpty
    }
    
    private var canUpload: Bool {
        hasSelectedFiles && !isUploading && !assetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var selectedFileItems: [FileItem] {
        var items: [FileItem] = []
        
        // Add photo picker results
        for (index, result) in selectedFiles.enumerated() {
            items.append(FileItem(
                id: "photo_\(index)",
                name: "Photo \(index + 1)",
                icon: "photo",
                color: .blue,
                size: nil
            ))
        }
        
        // Add document picker results
        for (index, url) in selectedDocuments.enumerated() {
            let name = url.lastPathComponent
            let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
            items.append(FileItem(
                id: "doc_\(index)",
                name: name,
                icon: iconForFile(url),
                color: colorForFile(url),
                size: size
            ))
        }
        
        return items
    }
    
    private var overallProgress: Double {
        guard !uploadProgress.isEmpty else { return 0 }
        let totalProgress = uploadProgress.values.reduce(0, +)
        return totalProgress / Double(uploadProgress.count)
    }
    
    // MARK: - Helper Methods
    
    private func removeFile(id: String) {
        if id.hasPrefix("photo_") {
            let index = Int(id.replacingOccurrences(of: "photo_", with: "")) ?? 0
            if index < selectedFiles.count {
                selectedFiles.remove(at: index)
            }
        } else if id.hasPrefix("doc_") {
            let index = Int(id.replacingOccurrences(of: "doc_", with: "")) ?? 0
            if index < selectedDocuments.count {
                selectedDocuments.remove(at: index)
            }
        }
    }
    
    private func iconForFile(_ url: URL) -> String {
        let fileExtension = url.pathExtension.lowercased()
        switch fileExtension {
        case "pdf":
            return "doc.text"
        case "jpg", "jpeg", "png", "gif", "bmp":
            return "photo"
        case "mp4", "mov", "avi", "mkv":
            return "video"
        case "mp3", "wav", "aac", "flac":
            return "music.note"
        case "zip", "rar", "7z":
            return "archivebox"
        default:
            return "doc"
        }
    }
    
    private func colorForFile(_ url: URL) -> Color {
        let fileExtension = url.pathExtension.lowercased()
        switch fileExtension {
        case "pdf":
            return .red
        case "jpg", "jpeg", "png", "gif", "bmp":
            return .blue
        case "mp4", "mov", "avi", "mkv":
            return .purple
        case "mp3", "wav", "aac", "flac":
            return .green
        case "zip", "rar", "7z":
            return .orange
        default:
            return .gray
        }
    }
    
    private func handleCameraImage(_ image: UIImage) {
        // Convert UIImage to data and add to upload queue
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            // Create temporary URL for the image
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("camera_\(UUID().uuidString).jpg")
            try? imageData.write(to: tempURL)
            selectedDocuments.append(tempURL)
        }
    }
    
    private func uploadAssets() {
        guard canUpload else { return }
        
        isUploading = true
        uploadProgress.removeAll()
        completedUploads.removeAll()
        uploadErrors.removeAll()
        
        Task {
            await uploadSelectedFiles()
        }
    }
    
    private func uploadSelectedFiles() async {
        let tags = assetTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Upload photos
        for (index, photoResult) in selectedFiles.enumerated() {
            let fileId = "photo_\(index)"
            await uploadPhoto(photoResult, fileId: fileId, tags: tags)
        }
        
        // Upload documents
        for (index, documentURL) in selectedDocuments.enumerated() {
            let fileId = "doc_\(index)"
            await uploadDocument(documentURL, fileId: fileId, tags: tags)
        }
        
        // Complete upload process
        isUploading = false
        
        if !completedUploads.isEmpty {
            onUploadComplete(completedUploads)
            dismiss()
        }
    }
    
    private func uploadPhoto(_ photoResult: PHPickerResult, fileId: String, tags: [String]) async {
        uploadProgress[fileId] = 0
        
        do {
            let imageData = try await loadImageData(from: photoResult)
            
            // Simulate upload progress
            for i in 1...10 {
                uploadProgress[fileId] = Double(i) / 10.0
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
            
            let metadata = AssetMetadata()
            let fileName = assetName.isEmpty ? "Photo \(fileId)" : "\(assetName)_\(fileId)"
            
            let asset = try await viewModel.uploadAsset(
                data: imageData,
                name: fileName,
                type: .image,
                metadata: metadata
            )
            
            var uploadedAsset = asset
            uploadedAsset.category = assetCategory.isEmpty ? nil : assetCategory
            uploadedAsset.tags = tags
            uploadedAsset.description = assetDescription.isEmpty ? nil : assetDescription
            uploadedAsset.isPublic = isPublic
            
            let finalAsset = try await viewModel.updateAsset(uploadedAsset)
            completedUploads.append(finalAsset)
            
        } catch {
            uploadErrors.append("Failed to upload \(fileId): \(error.localizedDescription)")
        }
        
        uploadProgress[fileId] = 1.0
    }
    
    private func uploadDocument(_ documentURL: URL, fileId: String, tags: [String]) async {
        uploadProgress[fileId] = 0
        
        do {
            let documentData = try Data(contentsOf: documentURL)
            
            // Simulate upload progress
            for i in 1...10 {
                uploadProgress[fileId] = Double(i) / 10.0
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
            
            let metadata = AssetMetadata()
            let fileName = assetName.isEmpty ? documentURL.lastPathComponent : "\(assetName)_\(documentURL.lastPathComponent)"
            
            let asset = try await viewModel.uploadAsset(
                data: documentData,
                name: fileName,
                type: selectedType,
                metadata: metadata
            )
            
            var uploadedAsset = asset
            uploadedAsset.category = assetCategory.isEmpty ? nil : assetCategory
            uploadedAsset.tags = tags
            uploadedAsset.description = assetDescription.isEmpty ? nil : assetDescription
            uploadedAsset.isPublic = isPublic
            
            let finalAsset = try await viewModel.updateAsset(uploadedAsset)
            completedUploads.append(finalAsset)
            
        } catch {
            uploadErrors.append("Failed to upload \(documentURL.lastPathComponent): \(error.localizedDescription)")
        }
        
        uploadProgress[fileId] = 1.0
    }
    
    private func loadImageData(from result: PHPickerResult) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: AssetManagementServiceError.uploadFailed("No image data available"))
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct UploadMethodButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(color.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FileItem {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let size: Int?
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}

// MARK: - Photo Picker

struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedFiles: [PHPickerResult]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 10
        configuration.filter = .any(of: [.images, .videos])
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView
        
        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.selectedFiles = results
            parent.dismiss()
        }
    }
}

// MARK: - Document Picker

struct DocumentPickerView: UIViewControllerRepresentable {
    @Binding var selectedDocuments: [URL]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.selectedDocuments = urls
            parent.dismiss()
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AssetUploadView(
        viewModel: AssetManagementViewModel(service: MockAssetManagementService())
    ) { assets in
        print("Uploaded \(assets.count) assets")
    }
}
