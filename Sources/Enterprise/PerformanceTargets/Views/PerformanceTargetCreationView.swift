//
//  PerformanceTargetCreationView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

struct PerformanceTargetCreationView: View {
    @ObservedObject var viewModel: PerformanceTargetsViewModel
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var metricType: MetricType = .custom
    @State private var targetValue: String = ""
    @State private var unit: String = ""
    @State private var period: TimePeriod = .monthly
    @State private var recurrence: Recurrence = .none
    @State private var navigationPath = NavigationPath()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SimpleAdaptiveNavigationView(path: $navigationPath) {
            Form {
                Section(header: Text("Target Info")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    Picker("Metric Type", selection: $metricType) {
                        ForEach(MetricType.allCases, id: \ .self) { metric in
                            Text(metric.rawValue).tag(metric)
                        }
                    }
                    TextField("Target Value", text: $targetValue)
                        .keyboardType(.decimalPad)
                    TextField("Unit", text: $unit)
                }
                Section(header: Text("Schedule")) {
                    Picker("Period", selection: $period) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.description).tag(period)
                        }
                    }
                    Picker("Recurrence", selection: $recurrence) {
                        ForEach(Recurrence.allCases, id: \.self) { rec in
                            Text(rec.rawValue).tag(rec)
                        }
                    }
                }
            }
            .navigationTitle("New Performance Target")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    Task {
                        let value = Double(targetValue) ?? 0
                        await viewModel.saveNewTarget(
                            name: name,
                            description: description.isEmpty ? nil : description,
                            metricType: metricType,
                            targetValue: value,
                            unit: unit,
                            period: period,
                            recurrence: recurrence
                        )
                        dismiss()
                    }
                }
                .disabled(name.isEmpty || targetValue.isEmpty || unit.isEmpty)
            )
            // Error alert
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }
}

#Preview {
    PerformanceTargetCreationView()
}
