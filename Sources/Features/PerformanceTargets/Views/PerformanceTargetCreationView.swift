//
//  PerformanceTargetCreationView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

struct PerformanceTargetCreationView: View {
    @State private var name: String = ""
    @State private var metricType: MetricType = .custom
    @State private var targetValue: String = ""
    @State private var unit: String = ""
    @State private var period: TimePeriod = .monthly
    @State private var recurrence: Recurrence = .none
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Target Info")) {
                    TextField("Name", text: $name)
                    Picker("Metric", selection: $metricType) {
                        ForEach(MetricType.allCases, id: \.self) { metric in
                            Text(metric.rawValue).tag(metric)
                        }
                    }
                    TextField("Value", text: $targetValue)
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
                    // TODO: Save target
                    dismiss()
                }.disabled(name.isEmpty || targetValue.isEmpty || unit.isEmpty)
            )
        }
    }
}

#Preview {
    PerformanceTargetCreationView()
}
