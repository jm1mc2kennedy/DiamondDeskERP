//
//  CreateProjectBoardSheet.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI
import Combine

struct CreateProjectBoardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateProjectBoardViewModel()
    
    // Form State
    @State private var boardName = ""
    @State private var boardDescription = ""
    @State private var selectedViewType: ProjectBoardViewType = .kanban
    @State private var selectedStatus: ProjectBoardStatus = .planning
    @State private var selectedVisibility: ProjectBoardVisibility = .team
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var selectedMembers: Set<String> = []
    @State private var selectedTags: Set<String> = []
    @State private var customColor: Color = .blue
    @State private var enableNotifications = true
    @State private var autoArchive = false
    @State private var templateId: String?
    
    // UI State
    @State private var showingColorPicker = false
    @State private var showingMemberPicker = false
    @State private var showingTemplatePicker = false
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    // Accessibility
    @AccessibilityFocusState private var isNameFieldFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                configurationsSection
                membersAndPermissionsSection
                advancedOptionsSection
            }
            .navigationTitle("New Project Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel creating project board")
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createProjectBoard()
                    }
                    .disabled(!canCreate)
                    .accessibilityLabel("Create project board")
                    .accessibilityHint(canCreate ? "Creates the new project board" : "Please fill in required fields")
                }
            }
            .onAppear {
                isNameFieldFocused = true
                loadAvailableData()
            }
            .alert("Error Creating Board", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An unexpected error occurred")
            }
            .sheet(isPresented: $showingMemberPicker) {
                TeamMemberPickerSheet(selectedMembers: $selectedMembers)
            }
            .sheet(isPresented: $showingTemplatePicker) {
                ProjectTemplatePickerSheet(selectedTemplateId: $templateId)
            }
            .disabled(isCreating)
            .overlay {
                if isCreating {
                    LoadingOverlay(message: "Creating project board...")
                }
            }
        }
    }
    
    // MARK: - Form Sections
    
    private var basicInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Board name", text: $boardName)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityFocused($isNameFieldFocused)
                    .accessibilityLabel("Project board name")
                    .accessibilityHint("Enter a name for your project board")
                
                TextField("Description (optional)", text: $boardDescription, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .accessibilityLabel("Project board description")
                    .accessibilityHint("Enter an optional description for your project board")
            }
        } header: {
            Text("Basic Information")
                .foregroundColor(.primary)
        }
    }
    
    private var configurationsSection: some View {
        Section {
            VStack(spacing: 16) {
                // Board Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Default View")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(ProjectBoardViewType.allCases, id: \.self) { viewType in
                            BoardTypeCard(
                                viewType: viewType,
                                isSelected: selectedViewType == viewType
                            ) {
                                selectedViewType = viewType
                            }
                        }
                    }
                }
                
                // Status and Visibility
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("Status", selection: $selectedStatus) {
                            ForEach(ProjectBoardStatus.allCases, id: \.self) { status in
                                Text(status.displayName)
                                    .tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Visibility")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("Visibility", selection: $selectedVisibility) {
                            ForEach(ProjectBoardVisibility.allCases, id: \.self) { visibility in
                                Text(visibility.displayName)
                                    .tag(visibility)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                // Dates
                VStack(alignment: .leading, spacing: 8) {
                    Text("Timeline")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 16) {
                        DatePicker("Start", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                        
                        DatePicker("End", selection: $endDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                }
                
                // Color Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Board Color")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        ColorPicker("Board Color", selection: $customColor, supportsOpacity: false)
                            .labelsHidden()
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(customColor)
                            .frame(width: 40, height: 40)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            }
                        
                        Spacer()
                        
                        Button("Preset Colors") {
                            showingColorPicker = true
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                }
            }
        } header: {
            Text("Configuration")
                .foregroundColor(.primary)
        }
    }
    
    private var membersAndPermissionsSection: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Text("Team Members")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button("Add Members") {
                        showingMemberPicker = true
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                
                if selectedMembers.isEmpty {
                    Text("No members added yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(Array(selectedMembers), id: \.self) { memberId in
                            MemberChip(memberId: memberId) {
                                selectedMembers.remove(memberId)
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Team & Permissions")
                .foregroundColor(.primary)
        }
    }
    
    private var advancedOptionsSection: some View {
        Section {
            VStack(spacing: 12) {
                Toggle("Enable Notifications", isOn: $enableNotifications)
                    .accessibilityHint("Receive notifications for board updates")
                
                Toggle("Auto-archive completed tasks", isOn: $autoArchive)
                    .accessibilityHint("Automatically archive tasks when marked complete")
                
                HStack {
                    Text("Use Template")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if let templateId = templateId {
                        Text("Template Selected")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                    
                    Button(templateId == nil ? "Choose Template" : "Change") {
                        showingTemplatePicker = true
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
            }
        } header: {
            Text("Advanced Options")
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canCreate: Bool {
        !boardName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        startDate <= endDate &&
        !isCreating
    }
    
    // MARK: - Actions
    
    private func createProjectBoard() {
        guard canCreate else { return }
        
        Task {
            await performCreation()
        }
    }
    
    @MainActor
    private func performCreation() async {
        isCreating = true
        errorMessage = nil
        
        do {
            let board = ProjectBoard(
                id: UUID().uuidString,
                name: boardName.trimmingCharacters(in: .whitespacesAndNewlines),
                description: boardDescription.isEmpty ? nil : boardDescription,
                ownerId: UserDefaults.standard.string(forKey: "currentUserId") ?? "",
                defaultViewType: selectedViewType,
                status: selectedStatus,
                visibility: selectedVisibility,
                startDate: startDate,
                endDate: endDate,
                memberIds: Array(selectedMembers),
                tags: Array(selectedTags),
                customColor: customColor.toHex(),
                settings: ProjectBoardSettings(
                    enableNotifications: enableNotifications,
                    autoArchiveCompleted: autoArchive,
                    allowGuestAccess: selectedVisibility == .public
                ),
                createdAt: Date(),
                modifiedAt: Date()
            )
            
            try await viewModel.createProjectBoard(board, fromTemplate: templateId)
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isCreating = false
    }
    
    private func loadAvailableData() {
        Task {
            await viewModel.loadAvailableMembers()
        }
    }
}

// MARK: - Supporting Views

private struct BoardTypeCard: View {
    let viewType: ProjectBoardViewType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: viewType.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accentColor)
                
                Text(viewType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor, lineWidth: isSelected ? 0 : 1)
                    }
            }
        }
        .buttonStyle(.plain)
        .accessibilityRole(.button)
        .accessibilityLabel("\(viewType.displayName) view type")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct MemberChip: View {
    let memberId: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(memberId) // In real app, would resolve to user name
                .font(.caption)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Remove \(memberId)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.1))
        .clipShape(Capsule())
    }
}

private struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Extensions

extension ProjectBoardViewType {
    var iconName: String {
        switch self {
        case .kanban: return "rectangle.split.3x1"
        case .table: return "tablecells"
        case .calendar: return "calendar"
        case .timeline: return "timeline.selection"
        }
    }
    
    var displayName: String {
        switch self {
        case .kanban: return "Kanban"
        case .table: return "Table"
        case .calendar: return "Calendar"
        case .timeline: return "Timeline"
        }
    }
}

extension ProjectBoardStatus {
    var displayName: String {
        switch self {
        case .planning: return "Planning"
        case .active: return "Active"
        case .onHold: return "On Hold"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }
}

extension ProjectBoardVisibility {
    var displayName: String {
        switch self {
        case .private: return "Private"
        case .team: return "Team"
        case .public: return "Public"
        }
    }
}

extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return String(format: "#%02X%02X%02X",
                     Int(red * 255),
                     Int(green * 255),
                     Int(blue * 255))
    }
}

#Preview {
    CreateProjectBoardSheet()
}
