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

    private let service = PerformanceTargetsService.shared

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
}
