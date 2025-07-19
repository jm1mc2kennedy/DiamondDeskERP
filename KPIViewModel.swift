// KPIViewModel.swift
// Diamond Desk ERP

import Foundation
import CloudKit
import SwiftUI

@MainActor
class KPIViewModel: ObservableObject {
    @Published var kpis: [KPIModel] = []
    @Published var isLoading = false
    private let repo: KPIRepository
    private let storeCode: String

    init(repo: KPIRepository = CloudKitKPIRepository(), storeCode: String) {
        self.repo = repo
        self.storeCode = storeCode
        Task { await fetchKPIs() }
    }

    func fetchKPIs() async {
        isLoading = true
        do {
            let result = try await repo.fetchForStore(storeCode)
            kpis = result
        } catch {
            kpis = []
        }
        isLoading = false
    }
}
