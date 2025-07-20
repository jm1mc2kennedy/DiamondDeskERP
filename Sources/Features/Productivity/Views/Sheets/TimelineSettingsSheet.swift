//
//  TimelineSettingsSheet.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI

struct TimelineSettingsSheet: View {
    @Binding var settings: TimelineSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var tempSettings: TimelineSettings
    
    init(settings: Binding<TimelineSettings>) {
        self._settings = settings
        self._tempSettings = State(initialValue: settings.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // View Mode Section
                Section {
                    Picker("Time Scale", selection: $tempSettings.timeScale) {
                        ForEach(TimelineScale.allCases, id: \.self) { scale in
                            Text(scale.displayName).tag(scale)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if tempSettings.timeScale == .custom {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Custom Scale")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text("Days per Unit:")
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Stepper(
                                    "\(tempSettings.customDaysPerUnit) day\(tempSettings.customDaysPerUnit == 1 ? "" : "s")",
                                    value: $tempSettings.customDaysPerUnit,
                                    in: 1...30
                                )
                            }
                        }
                    }
                } header: {
                    Text("Timeline View")
                } footer: {
                    Text("Choose how the timeline displays time periods. Custom scale allows you to set specific day intervals.")
                }
                
                // Display Options Section
                Section {
                    Toggle("Show Weekends", isOn: $tempSettings.showWeekends)
                    
                    Toggle("Show Holidays", isOn: $tempSettings.showHolidays)
                    
                    Toggle("Show Milestones", isOn: $tempSettings.showMilestones)
                    
                    Toggle("Show Dependencies", isOn: $tempSettings.showDependencies)
                    
                    Toggle("Show Critical Path", isOn: $tempSettings.showCriticalPath)
                } header: {
                    Text("Display Options")
                } footer: {
                    Text("Control which elements are visible on the timeline to reduce clutter and focus on what matters.")
                }
                
                // Task Display Section
                Section {
                    Picker("Task Height", selection: $tempSettings.taskHeight) {
                        Text("Compact").tag(TaskHeight.compact)
                        Text("Normal").tag(TaskHeight.normal)
                        Text("Comfortable").tag(TaskHeight.comfortable)
                    }
                    .pickerStyle(.segmented)
                    
                    Toggle("Show Task Progress", isOn: $tempSettings.showTaskProgress)
                    
                    Toggle("Show Task Labels", isOn: $tempSettings.showTaskLabels)
                    
                    Toggle("Show Assignee Avatars", isOn: $tempSettings.showAssigneeAvatars)
                } header: {
                    Text("Task Appearance")
                } footer: {
                    Text("Customize how tasks appear on the timeline. Compact mode shows more tasks, while comfortable mode provides better readability.")
                }
                
                // Color and Styling Section
                Section {
                    Picker("Color Coding", selection: $tempSettings.colorCoding) {
                        Text("Priority").tag(ColorCoding.priority)
                        Text("Status").tag(ColorCoding.status)
                        Text("Assignee").tag(ColorCoding.assignee)
                        Text("Project").tag(ColorCoding.project)
                    }
                    .pickerStyle(.menu)
                    
                    Toggle("Use Dark Bars", isOn: $tempSettings.useDarkBars)
                    
                    HStack {
                        Text("Bar Opacity")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Slider(
                            value: $tempSettings.barOpacity,
                            in: 0.3...1.0,
                            step: 0.1
                        ) {
                            Text("Bar Opacity")
                        } minimumValueLabel: {
                            Text("30%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } maximumValueLabel: {
                            Text("100%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: 150)
                    }
                } header: {
                    Text("Visual Style")
                } footer: {
                    Text("Choose how tasks are colored and styled. Color coding helps distinguish between different aspects of your work.")
                }
                
                // Interaction Options Section
                Section {
                    Toggle("Enable Drag & Drop", isOn: $tempSettings.enableDragDrop)
                    
                    Toggle("Enable Resize", isOn: $tempSettings.enableResize)
                    
                    Toggle("Snap to Grid", isOn: $tempSettings.snapToGrid)
                    
                    Toggle("Auto-scroll Today", isOn: $tempSettings.autoScrollToday)
                } header: {
                    Text("Interaction")
                } footer: {
                    Text("Control how you can interact with tasks on the timeline. Drag & drop and resize allow direct manipulation of task schedules.")
                }
                
                // Date Range Section
                Section {
                    DatePicker(
                        "Start Date",
                        selection: $tempSettings.startDate,
                        displayedComponents: .date
                    )
                    
                    DatePicker(
                        "End Date",
                        selection: $tempSettings.endDate,
                        in: tempSettings.startDate...,
                        displayedComponents: .date
                    )
                    
                    HStack {
                        Text("Date Range")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(daysBetween) day\(daysBetween == 1 ? "" : "s")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                } header: {
                    Text("Timeline Range")
                } footer: {
                    Text("Set the date range for the timeline view. The timeline will show tasks within this period.")
                }
                
                // Reset Section
                Section {
                    Button("Reset to Defaults") {
                        tempSettings = TimelineSettings()
                    }
                    .foregroundColor(.red)
                } footer: {
                    Text("Reset all timeline settings to their default values.")
                }
            }
            .navigationTitle("Timeline Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        settings = tempSettings
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var daysBetween: Int {
        Calendar.current.dateComponents([.day], from: tempSettings.startDate, to: tempSettings.endDate).day ?? 0
    }
}

// MARK: - Supporting Types

struct TimelineSettings: Equatable {
    var timeScale: TimelineScale = .weeks
    var customDaysPerUnit: Int = 7
    
    // Display Options
    var showWeekends: Bool = true
    var showHolidays: Bool = true
    var showMilestones: Bool = true
    var showDependencies: Bool = true
    var showCriticalPath: Bool = false
    
    // Task Display
    var taskHeight: TaskHeight = .normal
    var showTaskProgress: Bool = true
    var showTaskLabels: Bool = true
    var showAssigneeAvatars: Bool = true
    
    // Color and Styling
    var colorCoding: ColorCoding = .priority
    var useDarkBars: Bool = false
    var barOpacity: Double = 0.8
    
    // Interaction
    var enableDragDrop: Bool = true
    var enableResize: Bool = true
    var snapToGrid: Bool = true
    var autoScrollToday: Bool = true
    
    // Date Range
    var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    var endDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
}

enum TimelineScale: CaseIterable {
    case days
    case weeks
    case months
    case quarters
    case custom
    
    var displayName: String {
        switch self {
        case .days:
            return "Days"
        case .weeks:
            return "Weeks"
        case .months:
            return "Months"
        case .quarters:
            return "Quarters"
        case .custom:
            return "Custom"
        }
    }
    
    var daysPerUnit: Int {
        switch self {
        case .days:
            return 1
        case .weeks:
            return 7
        case .months:
            return 30
        case .quarters:
            return 90
        case .custom:
            return 7 // Default, will be overridden by customDaysPerUnit
        }
    }
}

enum TaskHeight: CaseIterable {
    case compact
    case normal
    case comfortable
    
    var height: CGFloat {
        switch self {
        case .compact:
            return 24
        case .normal:
            return 32
        case .comfortable:
            return 44
        }
    }
    
    var fontSize: Font {
        switch self {
        case .compact:
            return .caption2
        case .normal:
            return .caption
        case .comfortable:
            return .subheadline
        }
    }
}

enum ColorCoding: CaseIterable {
    case priority
    case status
    case assignee
    case project
    
    var displayName: String {
        switch self {
        case .priority:
            return "Priority"
        case .status:
            return "Status"
        case .assignee:
            return "Assignee"
        case .project:
            return "Project"
        }
    }
}

#Preview {
    TimelineSettingsSheet(settings: .constant(TimelineSettings()))
}
