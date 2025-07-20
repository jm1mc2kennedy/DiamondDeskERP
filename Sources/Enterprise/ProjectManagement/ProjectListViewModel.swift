import Foundation

@MainActor
class ProjectListViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: ProjectService

    init(service: ProjectService = .shared) {
        self.service = service
    }

    /// Load all projects
    func loadProjects() async {
        isLoading = true
        errorMessage = nil
        do {
            projects = try await service.fetchProjects()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    /// Save a new project and reload list
    func saveNewProject(
        name: String,
        description: String?,
        startDate: Date,
        endDate: Date?,
        status: ProjectStatus
    ) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let newProject = Project(
                name: name,
                description: description,
                startDate: startDate,
                endDate: endDate,
                status: status
            )
            try await service.saveProject(newProject)
            await loadProjects()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
