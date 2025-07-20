// StoreReportViewModel.swift
// Diamond Desk ERP

import Foundation
import CloudKit
import SwiftUI

@MainActor
class StoreReportViewModel: ObservableObject {
    @Published var reports: [StoreReportModel] = []
    @Published var isLoading = false
    @Published var error: IdentifiableError?
    private let repo: StoreReportRepository
    private let storeCode: String
    private var range: ClosedRange<Date>?

    init(repo: StoreReportRepository = CloudKitStoreReportRepository(), storeCode: String, range: ClosedRange<Date>? = nil) {
        self.repo = repo
        self.storeCode = storeCode
        self.range = range
        Task { await fetchReports() }
    }

    func fetchReports() async {
        isLoading = true
        do {
            let result = try await repo.fetchForStore(storeCode, in: range)
            reports = result
            error = nil
        } catch {
            reports = []
            self.error = IdentifiableError(error)
        }
        isLoading = false
    }
}
