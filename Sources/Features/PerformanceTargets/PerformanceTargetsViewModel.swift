//
//  PerformanceTargetsViewModel.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation

@MainActor
class PerformanceTargetsViewModel: ObservableObject {
    @Published var targets: [PerformanceTarget] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: PerformanceTargetsService

    /// Initialize with injected service for testing or production
    init(service: PerformanceTargetsService = .shared) {
        self.service = service
    }

    func loadTargets() async {
        isLoading = true
        errorMessage = nil
        do {
            targets = try await service.fetchTargets()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteTarget(_ target: PerformanceTarget) async {
        do {
            try await service.deleteTarget(target)
            await loadTargets()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    /// Save a new performance target and reload list
    func saveNewTarget(name: String, description: String?, metricType: MetricType, targetValue: Double, unit: String, period: TimePeriod, recurrence: Recurrence) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let newTarget = PerformanceTarget(
                name: name,
                description: description,
                metricType: metricType,
                targetValue: targetValue,
                unit: unit,
                period: period,
                recurrence: recurrence
            )
            try await service.saveTarget(newTarget)
            await loadTargets()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
