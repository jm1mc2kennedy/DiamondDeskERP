// TaskViewModel.swift
// Diamond Desk ERP

import Foundation
import CloudKit
import SwiftUI

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskModel] = []
    @Published var isLoading = false
    private let repo: TaskRepository
    private let userRef: String

    init(repo: TaskRepository = CloudKitTaskRepository(), userRef: String) {
        self.repo = repo
        self.userRef = userRef
        Task { await fetchAssignedTasks() }
    }

    func fetchAssignedTasks() async {
        isLoading = true
        do {
            let result = try await repo.fetchAssigned(to: userRef)
            tasks = result
        } catch {
            // Optionally handle error
            tasks = []
        }
        isLoading = false
    }
}
