// TicketViewModel.swift
// Diamond Desk ERP

import Foundation
import CloudKit
import SwiftUI

@MainActor
class TicketViewModel: ObservableObject {
    @Published var tickets: [TicketModel] = []
    @Published var isLoading = false
    private let repo: TicketRepository
    private let userRef: String

    init(repo: TicketRepository = CloudKitTicketRepository(), userRef: String) {
        self.repo = repo
        self.userRef = userRef
        Task { await fetchAssignedTickets() }
    }

    func fetchAssignedTickets() async {
        isLoading = true
        do {
            let result = try await repo.fetchAssigned(to: userRef)
            tickets = result
        } catch {
            // Optionally handle error
            tickets = []
        }
        isLoading = false
    }
}
