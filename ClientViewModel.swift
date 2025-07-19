// ClientViewModel.swift
// Diamond Desk ERP

import Foundation
import CloudKit
import SwiftUI

@MainActor
class ClientViewModel: ObservableObject {
    @Published var clients: [ClientModel] = []
    @Published var isLoading = false
    private let repo: ClientRepository
    private let userRef: String

    init(repo: ClientRepository = CloudKitClientRepository(), userRef: String) {
        self.repo = repo
        self.userRef = userRef
        Task { await fetchAssignedClients() }
    }

    func fetchAssignedClients() async {
        isLoading = true
        do {
            let result = try await repo.fetchAssigned(to: userRef)
            clients = result
        } catch {
            clients = []
        }
        isLoading = false
    }
}
