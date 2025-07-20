//
//  ProjectBoardSettingsSheet.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI

struct ProjectBoardSettingsSheet: View {
    @Binding var projectBoard: ProjectBoard
    let onSave: (ProjectBoard) -> Void
    let onDelete: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var tempBoard: ProjectBoard
    @State private var showingDeleteAlert = false
    @State private var showingArchiveAlert = false
    @State private var showingColorPicker = false
    
    init(
        projectBoard: Binding<ProjectBoard>,
        onSave: @escaping (ProjectBoard) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self._projectBoard = projectBoard
        self.onSave = onSave
        self.onDelete = onDelete
        self._tempBoard = State(initialValue: projectBoard.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Information
                basicInfoSection
                
                // Board Settings
                boardSettingsSection
                
                // Workflow Configuration
                workflowSection
                
                // Permissions
                permissionsSection
                
                // Automation Rules
                automationSection
                
                // Templates
                templatesSection
                
                // Danger Zone
                if onDelete != nil {
                    dangerZoneSection
                }
            }
            .navigationTitle("Board Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(tempBoard)
                        projectBoard = tempBoard
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!hasChanges)
                }
            }
            .alert("Delete Board", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this board? This action cannot be undone and will permanently remove all tasks and data.")
            }
            .alert("Archive Board", isPresented: $showingArchiveAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Archive", role: .destructive) {
                    tempBoard.isArchived = true
                }
            } message: {
                Text("Archiving this board will hide it from active views. You can restore it later from archived boards.")
            }
        }
    }
    
    // MARK: - Content Sections
    
    private var basicInfoSection: some View {
        Section {
            HStack {
                TextField("Board Name", text: $tempBoard.name)
                    .textFieldStyle(.plain)
                
                Button(action: { showingColorPicker.toggle() }) {
                    Circle()
                        .fill(Color(hex: tempBoard.color) ?? .accentColor)
                        .frame(width: 24, height: 24)
                        .overlay {
                            Circle()
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        }
                }
                .popover(isPresented: $showingColorPicker) {
                    ColorPickerView(selectedColor: Binding(
                        get: { Color(hex: tempBoard.color) ?? .accentColor },
                        set: { tempBoard.color = $0.toHex() ?? tempBoard.color }
                    ))
                    .frame(width: 300, height: 400)
                }
            }
            
            TextField("Description", text: $tempBoard.description, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
        } header: {
            Text("Basic Information")
        }
    }
    
    private var boardSettingsSection: some View {
        Section {
            Picker("Default View", selection: $tempBoard.defaultView) {
                ForEach(ProjectBoardView.allCases, id: \.self) { view in
                    Text(view.displayName).tag(view)
                }
            }
            
            Toggle("Enable Kanban Board", isOn: $tempBoard.enableKanban)
            Toggle("Enable Calendar View", isOn: $tempBoard.enableCalendar)
            Toggle("Enable Timeline View", isOn: $tempBoard.enableTimeline)
            Toggle("Enable List View", isOn: $tempBoard.enableList)
            
            if tempBoard.enableKanban {
                NavigationLink("Configure Columns") {
                    BoardColumnsConfigView(columns: $tempBoard.columns)
                }
            }
        } header: {
            Text("Board Configuration")
        } footer: {
            Text("Choose which views are available for this board and set the default view for team members.")
        }
    }
    
    private var workflowSection: some View {
        Section {
            Toggle("Auto-assign Creator", isOn: $tempBoard.autoAssignCreator)
            
            Toggle("Require Due Dates", isOn: $tempBoard.requireDueDates)
            
            Toggle("Enable Dependencies", isOn: $tempBoard.enableDependencies)
            
            Toggle("Enable Time Tracking", isOn: $tempBoard.enableTimeTracking)
            
            Toggle("Enable Subtasks", isOn: $tempBoard.enableSubtasks)
            
            Picker("Default Priority", selection: $tempBoard.defaultPriority) {
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    Text(priority.displayName).tag(priority)
                }
            }
        } header: {
            Text("Workflow Settings")
        } footer: {
            Text("Configure how tasks behave on this board. These settings affect all new tasks created.")
        }
    }
    
    private var permissionsSection: some View {
        Section {
            Picker("Board Visibility", selection: $tempBoard.visibility) {
                Text("Private").tag(BoardVisibility.private)
                Text("Team").tag(BoardVisibility.team)
                Text("Organization").tag(BoardVisibility.organization)
                Text("Public").tag(BoardVisibility.public)
            }
            
            Toggle("Allow Guest Access", isOn: $tempBoard.allowGuestAccess)
            
            Toggle("Members Can Invite", isOn: $tempBoard.membersCanInvite)
            
            Toggle("Members Can Create Tasks", isOn: $tempBoard.membersCanCreateTasks)
            
            Toggle("Members Can Delete Tasks", isOn: $tempBoard.membersCanDeleteTasks)
            
            NavigationLink("Manage Members") {
                BoardMembersView(
                    boardId: tempBoard.id,
                    members: $tempBoard.members
                )
            }
        } header: {
            Text("Access & Permissions")
        } footer: {
            Text("Control who can access this board and what actions they can perform.")
        }
    }
    
    private var automationSection: some View {
        Section {
            Toggle("Auto-archive Completed", isOn: $tempBoard.autoArchiveCompleted)
            
            if tempBoard.autoArchiveCompleted {
                Picker("Archive After", selection: $tempBoard.autoArchiveDays) {
                    Text("1 day").tag(1)
                    Text("3 days").tag(3)
                    Text("1 week").tag(7)
                    Text("2 weeks").tag(14)
                    Text("1 month").tag(30)
                }
            }
            
            Toggle("Send Due Date Reminders", isOn: $tempBoard.sendDueDateReminders)
            
            if tempBoard.sendDueDateReminders {
                Picker("Reminder Timing", selection: $tempBoard.reminderDays) {
                    Text("Same day").tag(0)
                    Text("1 day before").tag(1)
                    Text("2 days before").tag(2)
                    Text("1 week before").tag(7)
                }
            }
            
            Toggle("Auto-assign Based on Tags", isOn: $tempBoard.autoAssignByTags)
            
            NavigationLink("Custom Automation Rules") {
                AutomationRulesView(boardId: tempBoard.id)
            }
        } header: {
            Text("Automation")
        } footer: {
            Text("Set up automatic actions to reduce manual work and keep your board organized.")
        }
    }
    
    private var templatesSection: some View {
        Section {
            Toggle("Enable Task Templates", isOn: $tempBoard.enableTaskTemplates)
            
            if tempBoard.enableTaskTemplates {
                NavigationLink("Manage Templates") {
                    TaskTemplatesView(boardId: tempBoard.id)
                }
            }
            
            Toggle("Use Project Templates", isOn: $tempBoard.useProjectTemplates)
            
            NavigationLink("Import/Export Settings") {
                BoardImportExportView(board: tempBoard)
            }
        } header: {
            Text("Templates & Data")
        } footer: {
            Text("Manage task templates and data import/export options for this board.")
        }
    }
    
    private var dangerZoneSection: some View {
        Section {
            if !tempBoard.isArchived {
                Button("Archive Board") {
                    showingArchiveAlert = true
                }
                .foregroundColor(.orange)
            } else {
                Button("Unarchive Board") {
                    tempBoard.isArchived = false
                }
                .foregroundColor(.green)
            }
            
            Button("Delete Board") {
                showingDeleteAlert = true
            }
            .foregroundColor(.red)
        } header: {
            Text("Danger Zone")
        } footer: {
            Text("Archived boards are hidden but can be restored. Deleted boards cannot be recovered.")
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasChanges: Bool {
        tempBoard != projectBoard
    }
}

// MARK: - Supporting Views

struct ColorPickerView: View {
    @Binding var selectedColor: Color
    
    private let colors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, .brown,
        .gray, .black, .white
    ]
    
    private let gridColumns = Array(repeating: GridItem(.flexible()), count: 5)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Color")
                .font(.headline)
                .padding(.top)
            
            LazyVGrid(columns: gridColumns, spacing: 15) {
                ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                    Circle()
                        .fill(color)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Circle()
                                .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                        }
                        .onTapGesture {
                            selectedColor = color
                        }
                }
            }
            .padding()
            
            ColorPicker("Custom Color", selection: $selectedColor)
                .padding(.horizontal)
        }
    }
}

// MARK: - Supporting Types

enum ProjectBoardView: String, CaseIterable {
    case kanban = "kanban"
    case list = "list"
    case calendar = "calendar"
    case timeline = "timeline"
    
    var displayName: String {
        switch self {
        case .kanban:
            return "Kanban Board"
        case .list:
            return "List View"
        case .calendar:
            return "Calendar"
        case .timeline:
            return "Timeline"
        }
    }
}

enum BoardVisibility: String, CaseIterable {
    case `private` = "private"
    case team = "team"
    case organization = "organization"
    case `public` = "public"
}

// MARK: - Stub Views

struct BoardColumnsConfigView: View {
    @Binding var columns: [BoardColumn]
    
    var body: some View {
        Text("Board Columns Configuration")
            .navigationTitle("Columns")
    }
}

struct BoardMembersView: View {
    let boardId: String
    @Binding var members: [BoardMember]
    
    var body: some View {
        Text("Board Members Management")
            .navigationTitle("Members")
    }
}

struct AutomationRulesView: View {
    let boardId: String
    
    var body: some View {
        Text("Automation Rules Configuration")
            .navigationTitle("Automation")
    }
}

struct TaskTemplatesView: View {
    let boardId: String
    
    var body: some View {
        Text("Task Templates Management")
            .navigationTitle("Templates")
    }
}

struct BoardImportExportView: View {
    let board: ProjectBoard
    
    var body: some View {
        Text("Import/Export Board Data")
            .navigationTitle("Import/Export")
    }
}

// MARK: - Color Extension

extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
    
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ProjectBoardSettingsSheet(
        projectBoard: .constant(ProjectBoard.mockData.first!),
        onSave: { _ in },
        onDelete: { }
    )
}
