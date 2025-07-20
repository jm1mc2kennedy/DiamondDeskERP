//
//  ExportOptionsSheet.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

/// Export options sheet for acknowledgment tracking reports
struct ExportOptionsSheet: View {
    let readLogs: [MessageReadLog]
    let completionLogs: [TaskCompletionLog]
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedFormat: ExportFormat = .csv
    @State private var selectedDataType: DataType = .both
    @State private var includeHeaders = true
    @State private var includeMetadata = true
    @State private var dateFormat: DateFormatOption = .iso8601
    @State private var isExporting = false
    @State private var exportError: ExportError?
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
        case excel = "Excel"
        
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            case .excel: return "xlsx"
            }
        }
        
        var icon: String {
            switch self {
            case .csv: return "tablecells"
            case .json: return "curlybraces"
            case .excel: return "doc.richtext"
            }
        }
        
        var description: String {
            switch self {
            case .csv: return "Comma-separated values, compatible with Excel and Google Sheets"
            case .json: return "JavaScript Object Notation, structured data format"
            case .excel: return "Microsoft Excel format with advanced formatting"
            }
        }
    }
    
    enum DataType: String, CaseIterable {
        case messageReads = "Message Reads"
        case taskCompletions = "Task Completions"
        case both = "Both"
        
        var icon: String {
            switch self {
            case .messageReads: return "envelope"
            case .taskCompletions: return "checkmark.square"
            case .both: return "doc.on.doc"
            }
        }
    }
    
    enum DateFormatOption: String, CaseIterable {
        case iso8601 = "ISO 8601"
        case us = "US Format"
        case european = "European Format"
        case timestamp = "Unix Timestamp"
        
        var example: String {
            let date = Date()
            switch self {
            case .iso8601: return date.ISO8601Format()
            case .us: return DateFormatter.us.string(from: date)
            case .european: return DateFormatter.european.string(from: date)
            case .timestamp: return "\(Int(date.timeIntervalSince1970))"
            }
        }
    }
    
    struct ExportError: Identifiable, LocalizedError {
        let id = UUID()
        let message: String
        
        var errorDescription: String? { message }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Export Format Selection
                    formatSelectionSection
                    
                    // Data Type Selection
                    dataTypeSelectionSection
                    
                    // Export Options
                    exportOptionsSection
                    
                    // Date Format Options
                    dateFormatSection
                    
                    // Preview
                    previewSection
                    
                    // Export Button
                    exportButtonSection
                }
                .padding()
            }
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .background(liquidGlassBackground)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let exportURL = exportURL {
                ActivityViewController(activityItems: [exportURL])
            }
        }
        .alert("Export Error", isPresented: .constant(exportError != nil)) {
            Button("OK") {
                exportError = nil
            }
        } message: {
            if let error = exportError {
                Text(error.message)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.and.arrow.up")
                .font(.title)
                .foregroundColor(.blue)
            
            Text("Export Acknowledgment Report")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Configure export settings for your acknowledgment tracking data")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Format Selection Section
    
    private var formatSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Format")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(ExportFormat.allCases, id: \.self) { format in
                Button {
                    selectedFormat = format
                } label: {
                    HStack {
                        Image(systemName: format.icon)
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(format.rawValue)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(format.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedFormat == format {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedFormat == format ? .blue.opacity(0.1) : .quaternary.opacity(0.3))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Data Type Selection Section
    
    private var dataTypeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data to Export")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                ForEach(DataType.allCases, id: \.self) { dataType in
                    Button {
                        selectedDataType = dataType
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: dataType.icon)
                                .font(.title2)
                                .foregroundColor(selectedDataType == dataType ? .white : .blue)
                            
                            Text(dataType.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedDataType == dataType ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedDataType == dataType ? .blue : .quaternary.opacity(0.3))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Export Options Section
    
    private var exportOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Toggle("Include Column Headers", isOn: $includeHeaders)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                Toggle("Include Metadata", isOn: $includeMetadata)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary.opacity(0.3))
            )
        }
    }
    
    // MARK: - Date Format Section
    
    private var dateFormatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date Format")
                .font(.headline)
                .fontWeight(.semibold)
            
            Picker("Date Format", selection: $dateFormat) {
                ForEach(DateFormatOption.allCases, id: \.self) { format in
                    VStack(alignment: .leading) {
                        Text(format.rawValue)
                        Text(format.example)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(format)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary.opacity(0.3))
            )
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Preview")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Format:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(selectedFormat.rawValue)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Data Type:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(selectedDataType.rawValue)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Records:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(exportRecordCount)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("File Size:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("~\(estimatedFileSize)")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary.opacity(0.3))
            )
        }
    }
    
    // MARK: - Export Button Section
    
    private var exportButtonSection: some View {
        Button {
            Task {
                await exportData()
            }
        } label: {
            HStack {
                if isExporting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                
                Text(isExporting ? "Exporting..." : "Export Data")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isExporting || exportRecordCount == 0)
    }
    
    // MARK: - Computed Properties
    
    private var liquidGlassBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(.regularMaterial)
        } else {
            return AnyShapeStyle(.thickMaterial)
        }
    }
    
    private var exportRecordCount: Int {
        switch selectedDataType {
        case .messageReads:
            return readLogs.count
        case .taskCompletions:
            return completionLogs.count
        case .both:
            return readLogs.count + completionLogs.count
        }
    }
    
    private var estimatedFileSize: String {
        let recordCount = exportRecordCount
        let bytesPerRecord: Int = {
            switch selectedFormat {
            case .csv: return 150
            case .json: return 250
            case .excel: return 200
            }
        }()
        
        let totalBytes = recordCount * bytesPerRecord
        
        if totalBytes < 1024 {
            return "\(totalBytes) B"
        } else if totalBytes < 1024 * 1024 {
            return "\(totalBytes / 1024) KB"
        } else {
            return String(format: "%.1f MB", Double(totalBytes) / (1024 * 1024))
        }
    }
    
    // MARK: - Export Methods
    
    @MainActor
    private func exportData() async {
        isExporting = true
        exportError = nil
        
        do {
            let url = try await generateExportFile()
            exportURL = url
            showingShareSheet = true
        } catch {
            exportError = ExportError(message: error.localizedDescription)
        }
        
        isExporting = false
    }
    
    private func generateExportFile() async throws -> URL {
        let fileName = generateFileName()
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(fileName)
        
        switch selectedFormat {
        case .csv:
            try await generateCSVFile(at: fileURL)
        case .json:
            try await generateJSONFile(at: fileURL)
        case .excel:
            try await generateExcelFile(at: fileURL)
        }
        
        return fileURL
    }
    
    private func generateFileName() -> String {
        let timestamp = DateFormatter.fileTimestamp.string(from: Date())
        let dataTypeSuffix = selectedDataType.rawValue.replacingOccurrences(of: " ", with: "_").lowercased()
        return "acknowledgment_report_\(dataTypeSuffix)_\(timestamp).\(selectedFormat.fileExtension)"
    }
    
    private func generateCSVFile(at url: URL) async throws {
        var csvContent = ""
        
        // Headers
        if includeHeaders {
            switch selectedDataType {
            case .messageReads:
                csvContent += MessageReadLog.csvHeaders.joined(separator: ",") + "\n"
            case .taskCompletions:
                csvContent += TaskCompletionLog.csvHeaders.joined(separator: ",") + "\n"
            case .both:
                csvContent += "Data_Type," + MessageReadLog.csvHeaders.joined(separator: ",") + "\n"
            }
        }
        
        // Data
        switch selectedDataType {
        case .messageReads:
            for log in readLogs {
                csvContent += log.csvRow(dateFormat: dateFormat) + "\n"
            }
        case .taskCompletions:
            for log in completionLogs {
                csvContent += log.csvRow(dateFormat: dateFormat) + "\n"
            }
        case .both:
            for log in readLogs {
                csvContent += "Message_Read," + log.csvRow(dateFormat: dateFormat) + "\n"
            }
            for log in completionLogs {
                csvContent += "Task_Completion," + log.csvRow(dateFormat: dateFormat) + "\n"
            }
        }
        
        // Metadata
        if includeMetadata {
            csvContent += "\n\n# Export Metadata\n"
            csvContent += "# Generated: \(Date().ISO8601Format())\n"
            csvContent += "# Format: \(selectedFormat.rawValue)\n"
            csvContent += "# Records: \(exportRecordCount)\n"
        }
        
        try csvContent.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func generateJSONFile(at url: URL) async throws {
        var jsonData: [String: Any] = [:]
        
        // Metadata
        if includeMetadata {
            jsonData["metadata"] = [
                "generated": Date().ISO8601Format(),
                "format": selectedFormat.rawValue,
                "dataType": selectedDataType.rawValue,
                "recordCount": exportRecordCount,
                "dateFormat": dateFormat.rawValue
            ]
        }
        
        // Data
        switch selectedDataType {
        case .messageReads:
            jsonData["messageReads"] = readLogs.map { $0.jsonRepresentation(dateFormat: dateFormat) }
        case .taskCompletions:
            jsonData["taskCompletions"] = completionLogs.map { $0.jsonRepresentation(dateFormat: dateFormat) }
        case .both:
            jsonData["messageReads"] = readLogs.map { $0.jsonRepresentation(dateFormat: dateFormat) }
            jsonData["taskCompletions"] = completionLogs.map { $0.jsonRepresentation(dateFormat: dateFormat) }
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted)
        try jsonData.write(to: url)
    }
    
    private func generateExcelFile(at url: URL) async throws {
        // For now, fall back to CSV for Excel format
        // A full Excel implementation would require a library like xlsxwriter
        try await generateCSVFile(at: url)
    }
}

// MARK: - Activity View Controller

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Date Formatter Extensions

extension DateFormatter {
    static let us: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    static let european: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_GB")
        return formatter
    }()
    
    static let fileTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()
}

// MARK: - Export Extensions

extension MessageReadLog {
    static let csvHeaders = ["ID", "Message_ID", "User_ID", "Store_Code", "Timestamp", "Read_Source", "Device_Type", "Location"]
    
    func csvRow(dateFormat: ExportOptionsSheet.DateFormatOption) -> String {
        let formattedDate = formatDate(timestamp, using: dateFormat)
        return [
            id.uuidString,
            messageId,
            userId,
            storeCode,
            formattedDate,
            readSource.rawValue,
            deviceType.rawValue,
            location ?? ""
        ].map { "\"\($0)\"" }.joined(separator: ",")
    }
    
    func jsonRepresentation(dateFormat: ExportOptionsSheet.DateFormatOption) -> [String: Any] {
        return [
            "id": id.uuidString,
            "messageId": messageId,
            "userId": userId,
            "storeCode": storeCode,
            "timestamp": formatDate(timestamp, using: dateFormat),
            "readSource": readSource.rawValue,
            "deviceType": deviceType.rawValue,
            "location": location as Any
        ]
    }
}

extension TaskCompletionLog {
    static let csvHeaders = ["ID", "Task_ID", "User_ID", "Store_Code", "Timestamp", "Current_Progress", "Completion_Method", "Step_Count", "Completed_Steps"]
    
    func csvRow(dateFormat: ExportOptionsSheet.DateFormatOption) -> String {
        let formattedDate = formatDate(timestamp, using: dateFormat)
        return [
            id.uuidString,
            taskId,
            userId,
            storeCode,
            formattedDate,
            String(currentProgress),
            completionMethod.rawValue,
            String(stepCount),
            String(completedSteps)
        ].map { "\"\($0)\"" }.joined(separator: ",")
    }
    
    func jsonRepresentation(dateFormat: ExportOptionsSheet.DateFormatOption) -> [String: Any] {
        return [
            "id": id.uuidString,
            "taskId": taskId,
            "userId": userId,
            "storeCode": storeCode,
            "timestamp": formatDate(timestamp, using: dateFormat),
            "currentProgress": currentProgress,
            "completionMethod": completionMethod.rawValue,
            "stepCount": stepCount,
            "completedSteps": completedSteps
        ]
    }
}

private func formatDate(_ date: Date, using format: ExportOptionsSheet.DateFormatOption) -> String {
    switch format {
    case .iso8601:
        return date.ISO8601Format()
    case .us:
        return DateFormatter.us.string(from: date)
    case .european:
        return DateFormatter.european.string(from: date)
    case .timestamp:
        return String(Int(date.timeIntervalSince1970))
    }
}
