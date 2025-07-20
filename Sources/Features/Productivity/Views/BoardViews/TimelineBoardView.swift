//
//  TimelineBoardView.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI

struct TimelineBoardView: View {
    let tasks: [ProjectTask]
    let onTaskTap: (ProjectTask) -> Void
    let onTaskResize: (ProjectTask, (start: Date?, end: Date?)) -> Void
    
    @State private var timelineScale: TimelineScale = .weeks
    @State private var timelineRange: DateInterval
    @State private var scrollPosition: CGFloat = 0
    @State private var showingTimelineSettings = false
    @State private var selectedTaskId: String?
    @State private var draggedTask: ProjectTask?
    @State private var dragOffset: CGSize = .zero
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.calendar) private var calendar
    
    // Timeline Configuration
    private let timelineHeight: CGFloat = 80
    private let taskRowHeight: CGFloat = 40
    private let headerHeight: CGFloat = 60
    
    init(tasks: [ProjectTask], onTaskTap: @escaping (ProjectTask) -> Void, onTaskResize: @escaping (ProjectTask, (start: Date?, end: Date?)) -> Void) {
        self.tasks = tasks
        self.onTaskTap = onTaskTap
        self.onTaskResize = onTaskResize
        
        // Initialize timeline range based on tasks
        let now = Date()
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let endDate = calendar.date(byAdding: .month, value: 6, to: now) ?? now
        
        self._timelineRange = State(initialValue: DateInterval(start: startDate, end: endDate))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            timelineHeader
            
            Divider()
            
            timelineContent
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingTimelineSettings) {
            TimelineSettingsSheet(
                scale: $timelineScale,
                range: $timelineRange
            )
        }
    }
    
    // MARK: - Timeline Header
    
    private var timelineHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Timeline View")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Settings") {
                        showingTimelineSettings = true
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    
                    Picker("Scale", selection: $timelineScale) {
                        ForEach(TimelineScale.allCases, id: \.self) { scale in
                            Text(scale.displayName).tag(scale)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
            }
            
            // Timeline Legend
            HStack {
                HStack(spacing: 16) {
                    TimelineLegendItem(color: .blue, label: "In Progress")
                    TimelineLegendItem(color: .green, label: "Completed")
                    TimelineLegendItem(color: .orange, label: "Overdue")
                    TimelineLegendItem(color: .red, label: "Critical")
                }
                .font(.caption2)
                
                Spacer()
                
                Text("\(visibleTasks.count) of \(tasks.count) tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
    }
    
    // MARK: - Timeline Content
    
    private var timelineContent: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            VStack(spacing: 0) {
                // Date Header
                dateHeaderView
                
                // Task Rows
                LazyVStack(spacing: 1) {
                    ForEach(visibleTasks) { task in
                        TimelineTaskRow(
                            task: task,
                            timelineRange: timelineRange,
                            timelineScale: timelineScale,
                            timelineWidth: timelineWidth,
                            isSelected: selectedTaskId == task.id,
                            onTaskTap: { onTaskTap(task) },
                            onTaskSelect: { selectedTaskId = task.id },
                            onTaskResize: { newDates in
                                onTaskResize(task, newDates)
                            }
                        )
                    }
                }
                
                // Add some bottom padding
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
        .onChange(of: timelineScale) { _, _ in
            // Recalculate timeline when scale changes
        }
    }
    
    // MARK: - Date Header
    
    private var dateHeaderView: some View {
        HStack(spacing: 0) {
            // Task Name Column Header
            VStack {
                Text("Task")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .frame(width: 200, height: headerHeight)
            .background(.regularMaterial)
            
            // Timeline Header
            HStack(spacing: 0) {
                ForEach(timelinePeriods, id: \.start) { period in
                    VStack(spacing: 4) {
                        Text(period.start, formatter: periodFormatter)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        if timelineScale == .days {
                            Text(period.start, formatter: dayFormatter)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: periodWidth, height: headerHeight)
                    .background(isCurrentPeriod(period) ? Color.accentColor.opacity(0.1) : .regularMaterial)
                    .overlay {
                        Rectangle()
                            .fill(Color.primary.opacity(0.1))
                            .frame(width: 1)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
        .background(.regularMaterial)
    }
    
    // MARK: - Computed Properties
    
    private var visibleTasks: [ProjectTask] {
        tasks.filter { task in
            // Show tasks that have due dates or estimated dates within the timeline range
            if let dueDate = task.dueDate {
                return timelineRange.contains(dueDate)
            }
            // Could also include tasks based on creation date or other criteria
            return false
        }
        .sorted { task1, task2 in
            // Sort by priority first, then by due date
            if task1.priority != task2.priority {
                return task1.priority.sortOrder < task2.priority.sortOrder
            }
            
            guard let date1 = task1.dueDate, let date2 = task2.dueDate else {
                return task1.dueDate != nil
            }
            
            return date1 < date2
        }
    }
    
    private var timelinePeriods: [DateInterval] {
        var periods: [DateInterval] = []
        let duration = timelineScale.periodDuration
        
        var currentDate = timelineRange.start
        while currentDate < timelineRange.end {
            let periodEnd = min(
                calendar.date(byAdding: duration.component, value: duration.value, to: currentDate) ?? currentDate,
                timelineRange.end
            )
            
            periods.append(DateInterval(start: currentDate, end: periodEnd))
            currentDate = periodEnd
        }
        
        return periods
    }
    
    private var timelineWidth: CGFloat {
        CGFloat(timelinePeriods.count) * periodWidth
    }
    
    private var periodWidth: CGFloat {
        switch timelineScale {
        case .days: return 60
        case .weeks: return 100
        case .months: return 120
        case .quarters: return 150
        }
    }
    
    // MARK: - Helper Methods
    
    private func isCurrentPeriod(_ period: DateInterval) -> Bool {
        period.contains(Date())
    }
    
    // MARK: - Formatters
    
    private var periodFormatter: DateFormatter {
        let formatter = DateFormatter()
        switch timelineScale {
        case .days:
            formatter.dateFormat = "MMM d"
        case .weeks:
            formatter.dateFormat = "MMM d"
        case .months:
            formatter.dateFormat = "MMM yyyy"
        case .quarters:
            formatter.dateFormat = "QQQ yyyy"
        }
        return formatter
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }
}

// MARK: - Timeline Task Row

struct TimelineTaskRow: View {
    let task: ProjectTask
    let timelineRange: DateInterval
    let timelineScale: TimelineScale
    let timelineWidth: CGFloat
    let isSelected: Bool
    let onTaskTap: () -> Void
    let onTaskSelect: () -> Void
    let onTaskResize: ((start: Date?, end: Date?)) -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var isResizing = false
    @State private var resizeHandle: ResizeHandle?
    
    @Environment(\.calendar) private var calendar
    
    private enum ResizeHandle {
        case start, end
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Task Info Column
            taskInfoColumn
            
            // Timeline Column
            timelineColumn
        }
        .frame(height: 40)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemBackground))
        .overlay {
            if isSelected {
                Rectangle()
                    .stroke(Color.accentColor, lineWidth: 1)
            }
        }
    }
    
    private var taskInfoColumn: some View {
        Button(action: onTaskTap) {
            HStack {
                // Priority indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(task.priority.color)
                    .frame(width: 4, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text(task.status.displayName)
                            .font(.caption2)
                            .foregroundColor(task.status.color)
                        
                        if !task.assigneeIds.isEmpty {
                            Text("• \(task.assigneeIds.count) assigned")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
        .frame(width: 200)
        .background(.regularMaterial)
        .onTapGesture {
            onTaskSelect()
        }
    }
    
    private var timelineColumn: some View {
        ZStack(alignment: .leading) {
            // Timeline background with grid lines
            timelineBackground
            
            // Task bar
            if let taskBar = taskBarView {
                taskBar
            }
        }
        .frame(width: timelineWidth, height: 40)
        .clipped()
    }
    
    private var timelineBackground: some View {
        HStack(spacing: 0) {
            ForEach(0..<Int(timelineWidth / periodWidth), id: \.self) { index in
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: periodWidth)
                    .overlay {
                        Rectangle()
                            .fill(Color.primary.opacity(0.05))
                            .frame(width: 1)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
            }
        }
    }
    
    private var taskBarView: some View? {
        guard let dueDate = task.dueDate else { return nil }
        
        // Calculate position and width based on task dates
        let startDate = task.dueDate ?? dueDate // In real app, use task start date
        let endDate = dueDate
        
        let startPosition = positionForDate(startDate)
        let endPosition = positionForDate(endDate)
        let barWidth = max(endPosition - startPosition, 20) // Minimum width
        
        guard startPosition < timelineWidth && endPosition > 0 else { return nil }
        
        return HStack(spacing: 0) {
            // Resize handle (start)
            Rectangle()
                .fill(task.status.color.opacity(0.3))
                .frame(width: 4)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Handle start resize
                        }
                )
            
            // Task bar content
            Rectangle()
                .fill(task.status.color)
                .overlay {
                    HStack {
                        Text(task.title)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 4)
                        
                        Spacer()
                        
                        if !task.checklistItems.isEmpty {
                            let completed = task.checklistItems.filter { $0.isCompleted }.count
                            Text("\(completed)/\(task.checklistItems.count)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 4)
                        }
                    }
                }
            
            // Resize handle (end)
            Rectangle()
                .fill(task.status.color.opacity(0.3))
                .frame(width: 4)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Handle end resize
                        }
                )
        }
        .frame(width: barWidth, height: 24)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .offset(x: startPosition)
        .onTapGesture {
            onTaskTap()
        }
        .contextMenu {
            Button("Edit Task") {
                onTaskTap()
            }
            
            Button("Extend Timeline") {
                // Extend task timeline
            }
            
            if task.status != .completed {
                Button("Mark Complete") {
                    // Mark task complete
                }
            }
        }
    }
    
    private var periodWidth: CGFloat {
        switch timelineScale {
        case .days: return 60
        case .weeks: return 100
        case .months: return 120
        case .quarters: return 150
        }
    }
    
    private func positionForDate(_ date: Date) -> CGFloat {
        let timeElapsed = date.timeIntervalSince(timelineRange.start)
        let totalTime = timelineRange.duration
        let progress = timeElapsed / totalTime
        
        return max(0, CGFloat(progress) * timelineWidth)
    }
}

// MARK: - Supporting Views

private struct TimelineLegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 8)
            
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Timeline Scale

enum TimelineScale: String, CaseIterable {
    case days = "days"
    case weeks = "weeks"
    case months = "months"
    case quarters = "quarters"
    
    var displayName: String {
        switch self {
        case .days: return "Days"
        case .weeks: return "Weeks"
        case .months: return "Months"
        case .quarters: return "Quarters"
        }
    }
    
    var periodDuration: (component: Calendar.Component, value: Int) {
        switch self {
        case .days: return (.day, 1)
        case .weeks: return (.weekOfYear, 1)
        case .months: return (.month, 1)
        case .quarters: return (.month, 3)
        }
    }
}

// MARK: - Timeline Settings Sheet

struct TimelineSettingsSheet: View {
    @Binding var scale: TimelineScale
    @Binding var range: DateInterval
    @Environment(\.dismiss) private var dismiss
    
    @State private var startDate: Date
    @State private var endDate: Date
    
    init(scale: Binding<TimelineScale>, range: Binding<DateInterval>) {
        self._scale = scale
        self._range = range
        self._startDate = State(initialValue: range.wrappedValue.start)
        self._endDate = State(initialValue: range.wrappedValue.end)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Timeline Scale") {
                    Picker("Scale", selection: $scale) {
                        ForEach(TimelineScale.allCases, id: \.self) { timelineScale in
                            Text(timelineScale.displayName).tag(timelineScale)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Date Range") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section {
                    Button("Reset to Default") {
                        let now = Date()
                        let calendar = Calendar.current
                        startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
                        endDate = calendar.date(byAdding: .month, value: 6, to: now) ?? now
                        scale = .weeks
                    }
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
                        range = DateInterval(start: startDate, end: endDate)
                        dismiss()
                    }
                    .disabled(startDate >= endDate)
                }
            }
        }
    }
}

#Preview {
    TimelineBoardView(
        tasks: [
            ProjectTask(
                id: "1",
                projectBoardId: "board1",
                title: "Design user interface",
                description: nil,
                status: .inProgress,
                priority: .high,
                assigneeIds: ["user1"],
                createdBy: "user1",
                dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                tags: ["Design"],
                dependencyIds: [],
                checklistItems: [
                    ChecklistItem(id: "1", title: "Create wireframes", isCompleted: true, completedAt: Date(), completedBy: "user1"),
                    ChecklistItem(id: "2", title: "Design mockups", isCompleted: false, completedAt: nil, completedBy: nil)
                ],
                attachmentIds: [],
                createdAt: Date(),
                modifiedAt: Date()
            )
        ],
        onTaskTap: { _ in },
        onTaskResize: { _, _ in }
    )
}
