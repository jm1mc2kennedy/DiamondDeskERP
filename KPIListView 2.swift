// KPIListView.swift
// Diamond Desk ERP

import SwiftUI

struct KPIListView: View {
    @StateObject private var viewModel: KPIViewModel
    @State private var showNewKPISheet = false
    @State private var error: IdentifiableError?
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    init(storeCode: String) {
        _viewModel = StateObject(wrappedValue: KPIViewModel(storeCode: storeCode))
    }

    var body: some View {
        NavigationView {
            ErrorBoundary(error: $error, retryAction: {
                Task {
                    await viewModel.fetchKPIs()
                }
            }) {
                List {
                    // Loop through each KPI and display its details
                    ForEach(viewModel.kpis) { kpi in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Store: \(kpi.storeCode)")
                                .font(.headline)
                            Text("Date: \(kpi.date, formatter: itemFormatter)")
                                .font(.subheadline)
                            ForEach(kpi.metrics.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                Text("\(key): \(value, specifier: "%.2f")")
                                    .font(.caption)
                            }
                        }
                        .padding(8)
                        // Background styling with fallback for reduce transparency
                        .background {
                            if reduceTransparency {
                                Color(UIColor.systemBackground)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            }
                        }
                    }
                }
            }
            .navigationTitle("KPIs")
            .toolbar {
                // Toolbar button to present new KPI sheet
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewKPISheet.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add new KPI")
                }
            }
            .refreshable {
                await viewModel.fetchKPIs()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            // Present sheet for creating new KPI
            .sheet(isPresented: $showNewKPISheet) {
                NewKPISheet(storeCode: viewModel.storeCode) { result in
                    switch result {
                    case .success(let newKPI):
                        // Add the new KPI locally and dismiss
                        viewModel.kpis.append(newKPI)
                        showNewKPISheet = false
                    case .failure(let saveError):
                        error = IdentifiableError(saveError)
                    }
                }
            }
            // Show alert if there is an error
            .alert(item: $error) { error in
                Alert(title: Text("Error"),
                      message: Text(error.localizedDescription),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
}

// MARK: - New KPI Sheet View

private struct NewKPISheet: View {
    @Environment(\.dismiss) private var dismiss
    let storeCode: String
    var onComplete: (Result<KPIModel, Error>) -> Void

    @State private var date: Date = Date()
    @State private var metrics: [MetricEntry] = [MetricEntry(key: "", value: "")]
    @State private var showingSaveErrorAlert = false
    @State private var saveErrorMessage = ""

    // MetricEntry represents one key-value pair in metrics input
    private struct MetricEntry: Identifiable, Hashable {
        let id = UUID()
        var key: String
        var value: String
    }

    var body: some View {
        NavigationView {
            Form {
                // Date selection
                Section("Date") {
                    DatePicker("Select Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .accessibilityLabel("Date Picker")
                }

                // Metrics input as editable list
                Section("Metrics") {
                    ForEach($metrics) { $metric in
                        HStack {
                            TextField("Key", text: $metric.key)
                                .accessibilityLabel("Metric Key")
                                .textInputAutocapitalization(.none)
                                .disableAutocorrection(true)
                            Spacer()
                            TextField("Value", text: $metric.value)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .accessibilityLabel("Metric Value")
                        }
                    }
                    // Button to add new metric entry
                    Button {
                        metrics.append(MetricEntry(key: "", value: ""))
                    } label: {
                        Label("Add Metric", systemImage: "plus.circle")
                    }
                    .accessibilityLabel("Add new metric")
                }
            }
            .navigationTitle("New KPI")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel new KPI creation")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveKPI()
                    }
                    .accessibilityLabel("Save new KPI")
                }
            }
            // Show alert if save error occurs
            .alert("Save Failed", isPresented: $showingSaveErrorAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(saveErrorMessage)
            })
        }
    }

    // Validate metrics and save KPI
    private func saveKPI() {
        // Filter out empty metrics and validate keys and values
        let filteredMetrics = metrics.filter { !$0.key.trimmingCharacters(in: .whitespaces).isEmpty || !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !filteredMetrics.isEmpty else {
            showError(message: "Please enter at least one metric.")
            return
        }

        var metricsDict: [String: Double] = [:]
        for metric in filteredMetrics {
            let keyTrimmed = metric.key.trimmingCharacters(in: .whitespaces)
            guard !keyTrimmed.isEmpty else {
                showError(message: "Metric keys cannot be empty.")
                return
            }
            guard let doubleValue = Double(metric.value) else {
                showError(message: "Metric values must be valid numbers.")
                return
            }
            metricsDict[keyTrimmed] = doubleValue
        }

        // Create KPIModel with entered data
        let newKPI = KPIModel(id: UUID(), storeCode: storeCode, date: date, metrics: metricsDict)

        // Attempt save via repo
        Task {
            do {
                try await KPIRepository.shared.save(kpi: newKPI)
                DispatchQueue.main.async {
                    onComplete(.success(newKPI))
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    onComplete(.failure(error))
                    saveErrorMessage = error.localizedDescription
                    showingSaveErrorAlert = true
                }
            }
        }
    }

    private func showError(message: String) {
        saveErrorMessage = message
        showingSaveErrorAlert = true
    }
}

// MARK: - ErrorBoundary View

/// A view that catches errors and displays an alert with a retry button
struct ErrorBoundary<Content: View>: View {
    @Binding var error: IdentifiableError?
    let retryAction: () -> Void
    let content: () -> Content

    var body: some View {
        ZStack {
            content()
                // Present alert if error exists
                .alert(item: $error) { identifiableError in
                    Alert(title: Text("Error"),
                          message: Text(identifiableError.localizedDescription),
                          primaryButton: .default(Text("Retry"), action: retryAction),
                          secondaryButton: .cancel())
                }
        }
    }
}

// MARK: - IdentifiableError Wrapper

/// A wrapper to make Error identifiable for SwiftUI alerts
struct IdentifiableError: Identifiable, LocalizedError {
    let id = UUID()
    let underlyingError: Error

    var errorDescription: String? {
        (underlyingError as? LocalizedError)?.errorDescription ?? underlyingError.localizedDescription
    }

    init(_ error: Error) {
        self.underlyingError = error
    }
}

// MARK: - DateFormatter

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    KPIListView(storeCode: "demo-store")
}
