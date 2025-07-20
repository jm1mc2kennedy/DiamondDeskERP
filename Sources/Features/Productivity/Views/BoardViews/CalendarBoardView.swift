//
//  CalendarBoardView.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI
import EventKit

struct CalendarBoardView: View {
    let tasks: [ProjectTask]
    let onTaskTap: (ProjectTask) -> Void
    let onDateTap: (Date) -> Void
    
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showingTasksForDate = false
    @State private var tasksForSelectedDate: [ProjectTask] = []
    @State private var calendarViewMode: CalendarViewMode = .month
    @State private var showingCreateTask = false
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.calendar) private var calendar
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 0) {
            calendarHeader
            
            Divider()
            
            calendarContent
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingTasksForDate) {
            TasksForDateSheet(
                date: selectedDate,
                tasks: tasksForSelectedDate,
                onTaskTap: onTaskTap,
                onCreateTask: { onDateTap(selectedDate) }
            )
        }
        .sheet(isPresented: $showingCreateTask) {
            CreateProjectTaskSheet(projectBoardId: "") // Would get actual board ID
        }
        .onChange(of: selectedDate) { _, newDate in
            updateTasksForDate(newDate)
        }
    }
    
    // MARK: - Calendar Header
    
    private var calendarHeader: some View {
        VStack(spacing: 12) {
            // Month/Year Navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .accessibilityLabel("Previous month")
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(currentMonth, formatter: monthYearFormatter)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(tasksInCurrentMonth) tasks this month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .accessibilityLabel("Next month")
            }
            
            // View Mode Picker
            Picker("View Mode", selection: $calendarViewMode) {
                ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            // Today Button
            HStack {
                Button("Today") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentMonth = Date()
                        selectedDate = Date()
                    }
                }
                .font(.caption)
                .foregroundColor(.accentColor)
                
                Spacer()
                
                // Legend
                HStack(spacing: 16) {
                    LegendItem(color: .red, label: "Overdue")
                    LegendItem(color: .orange, label: "Due Soon")
                    LegendItem(color: .green, label: "Completed")
                    LegendItem(color: .blue, label: "In Progress")
                }
                .font(.caption2)
            }
        }
        .padding()
        .background(.regularMaterial)
    }
    
    // MARK: - Calendar Content
    
    private var calendarContent: some View {
        Group {
            switch calendarViewMode {
            case .month:
                monthView
            case .week:
                weekView
            case .agenda:
                agendaView
            }
        }
    }
    
    private var monthView: some View {
        VStack(spacing: 0) {
            // Weekday Headers
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .background(.regularMaterial)
            
            // Calendar Grid
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(daysInMonth, id: \.self) { date in
                    CalendarDayCell(
                        date: date,
                        tasks: tasksForDate(date),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                    ) {
                        selectedDate = date
                        updateTasksForDate(date)
                        if !tasksForDate(date).isEmpty {
                            showingTasksForDate = true
                        } else {
                            onDateTap(date)
                        }
                    }
                }
            }
        }
    }
    
    private var weekView: some View {
        WeekCalendarView(
            currentWeek: weekContaining(selectedDate),
            tasks: tasks,
            selectedDate: $selectedDate,
            onTaskTap: onTaskTap,
            onDateTap: onDateTap
        )
    }
    
    private var agendaView: some View {
        AgendaCalendarView(
            tasks: sortedTasksWithDates,
            selectedDate: $selectedDate,
            onTaskTap: onTaskTap,
            onDateTap: onDateTap
        )
    }
    
    // MARK: - Computed Properties
    
    private var weekdaySymbols: [String] {
        calendar.shortWeekdaySymbols
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let startOfMonth = monthInterval.start
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return []
        }
        
        // Get the first day of the week for the calendar grid
        let startWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysFromPreviousMonth = (startWeekday - calendar.firstWeekday + 7) % 7
        
        guard let firstDisplayDay = calendar.date(byAdding: .day, value: -daysFromPreviousMonth, to: startOfMonth) else {
            return []
        }
        
        // Generate 42 days (6 weeks) for the calendar grid
        var days: [Date] = []
        for i in 0..<42 {
            if let day = calendar.date(byAdding: .day, value: i, to: firstDisplayDay) {
                days.append(day)
            }
        }
        
        return days
    }
    
    private var tasksInCurrentMonth: Int {
        tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, equalTo: currentMonth, toGranularity: .month)
        }.count
    }
    
    private var sortedTasksWithDates: [ProjectTask] {
        tasks.filter { $0.dueDate != nil }
            .sorted { task1, task2 in
                guard let date1 = task1.dueDate, let date2 = task2.dueDate else { return false }
                return date1 < date2
            }
    }
    
    // MARK: - Helper Methods
    
    private func tasksForDate(_ date: Date) -> [ProjectTask] {
        tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
    }
    
    private func updateTasksForDate(_ date: Date) {
        tasksForSelectedDate = tasksForDate(date)
    }
    
    private func weekContaining(_ date: Date) -> [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return []
        }
        
        var days: [Date] = []
        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: weekInterval.start) {
                days.append(day)
            }
        }
        return days
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
    
    // MARK: - Formatters
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let tasks: [ProjectTask]
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let onTap: () -> Void
    
    @Environment(\.calendar) private var calendar
    
    private var dayNumber: String {
        String(calendar.component(.day, from: date))
    }
    
    private var taskStatusCounts: (overdue: Int, dueSoon: Int, completed: Int, inProgress: Int) {
        let now = Date()
        let threeDaysFromNow = calendar.date(byAdding: .day, value: 3, to: now) ?? now
        
        var overdue = 0
        var dueSoon = 0
        var completed = 0
        var inProgress = 0
        
        for task in tasks {
            switch task.status {
            case .completed:
                completed += 1
            case .inProgress:
                if date < now {
                    overdue += 1
                } else if date <= threeDaysFromNow {
                    dueSoon += 1
                } else {
                    inProgress += 1
                }
            default:
                if date < now {
                    overdue += 1
                } else if date <= threeDaysFromNow {
                    dueSoon += 1
                } else {
                    inProgress += 1
                }
            }
        }
        
        return (overdue, dueSoon, completed, inProgress)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Day Number
                Text(dayNumber)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(dayNumberColor)
                
                // Task Indicators
                if !tasks.isEmpty {
                    HStack(spacing: 2) {
                        let counts = taskStatusCounts
                        
                        if counts.overdue > 0 {
                            TaskIndicatorDot(count: counts.overdue, color: .red)
                        }
                        if counts.dueSoon > 0 {
                            TaskIndicatorDot(count: counts.dueSoon, color: .orange)
                        }
                        if counts.inProgress > 0 {
                            TaskIndicatorDot(count: counts.inProgress, color: .blue)
                        }
                        if counts.completed > 0 {
                            TaskIndicatorDot(count: counts.completed, color: .green)
                        }
                    }
                }
                
                Spacer(minLength: 0)
            }
            .frame(minHeight: 50)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 2)
                }
                if isToday && !isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view tasks for this date")
    }
    
    private var dayNumberColor: Color {
        if !isCurrentMonth {
            return .secondary.opacity(0.5)
        } else if isToday {
            return .accentColor
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .accentColor.opacity(0.1)
        } else if !isCurrentMonth {
            return .clear
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var accessibilityLabel: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        var label = dateFormatter.string(from: date)
        
        if !tasks.isEmpty {
            label += ", \(tasks.count) task\(tasks.count == 1 ? "" : "s")"
        }
        
        if isToday {
            label += ", today"
        }
        
        return label
    }
}

// MARK: - Supporting Views

private struct TaskIndicatorDot: View {
    let count: Int
    let color: Color
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .overlay {
                if count > 1 {
                    Text("\(min(count, 9))")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
            }
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Calendar View Mode

enum CalendarViewMode: String, CaseIterable {
    case month = "month"
    case week = "week"
    case agenda = "agenda"
    
    var displayName: String {
        switch self {
        case .month: return "Month"
        case .week: return "Week"
        case .agenda: return "Agenda"
        }
    }
}

// MARK: - Week Calendar View

struct WeekCalendarView: View {
    let currentWeek: [Date]
    let tasks: [ProjectTask]
    @Binding var selectedDate: Date
    let onTaskTap: (ProjectTask) -> Void
    let onDateTap: (Date) -> Void
    
    @Environment(\.calendar) private var calendar
    
    var body: some View {
        VStack(spacing: 0) {
            // Week Header
            HStack(spacing: 0) {
                ForEach(currentWeek, id: \.self) { date in
                    VStack(spacing: 4) {
                        Text(date, formatter: dayFormatter)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(date, formatter: dateFormatter)
                            .font(.headline)
                            .fontWeight(calendar.isDateInToday(date) ? .bold : .regular)
                            .foregroundColor(calendar.isDateInToday(date) ? .accentColor : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(calendar.isDate(date, inSameDayAs: selectedDate) ? Color.accentColor.opacity(0.1) : Color.clear)
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
            .background(.regularMaterial)
            
            // Week Tasks
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(currentWeek, id: \.self) { date in
                        let dayTasks = tasksForDate(date)
                        if !dayTasks.isEmpty {
                            WeekDayTasksView(
                                date: date,
                                tasks: dayTasks,
                                onTaskTap: onTaskTap
                            )
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func tasksForDate(_ date: Date) -> [ProjectTask] {
        tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
}

struct WeekDayTasksView: View {
    let date: Date
    let tasks: [ProjectTask]
    let onTaskTap: (ProjectTask) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(date, style: .date)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            ForEach(tasks) { task in
                Button(action: { onTaskTap(task) }) {
                    HStack {
                        Circle()
                            .fill(task.priority.color)
                            .frame(width: 8, height: 8)
                        
                        Text(task.title)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(task.status.displayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Agenda Calendar View

struct AgendaCalendarView: View {
    let tasks: [ProjectTask]
    @Binding var selectedDate: Date
    let onTaskTap: (ProjectTask) -> Void
    let onDateTap: (Date) -> Void
    
    @Environment(\.calendar) private var calendar
    
    private var groupedTasks: [(Date, [ProjectTask])] {
        let grouped = Dictionary(grouping: tasks) { task in
            guard let dueDate = task.dueDate else { return Date.distantPast }
            return calendar.startOfDay(for: dueDate)
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(groupedTasks, id: \.0) { date, dayTasks in
                    AgendaDaySection(
                        date: date,
                        tasks: dayTasks,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        onTaskTap: onTaskTap,
                        onDateTap: { selectedDate = date }
                    )
                }
            }
            .padding()
        }
    }
}

struct AgendaDaySection: View {
    let date: Date
    let tasks: [ProjectTask]
    let isSelected: Bool
    let onTaskTap: (ProjectTask) -> Void
    let onDateTap: () -> Void
    
    @Environment(\.calendar) private var calendar
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date Header
            Button(action: onDateTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(date, style: .date)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if calendar.isDateInToday(date) {
                            Text("Today")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(tasks.count) task\(tasks.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(isSelected ? Color.accentColor.opacity(0.1) : .regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            
            // Tasks for this date
            ForEach(tasks) { task in
                Button(action: { onTaskTap(task) }) {
                    HStack {
                        // Priority indicator
                        RoundedRectangle(cornerRadius: 2)
                            .fill(task.priority.color)
                            .frame(width: 4, height: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            HStack {
                                Text(task.status.displayName)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(task.status.color.opacity(0.2))
                                    .foregroundColor(task.status.color)
                                    .clipShape(Capsule())
                                
                                if !task.assigneeIds.isEmpty {
                                    Text("Assigned to \(task.assigneeIds.count)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        
                        Spacer()
                        
                        if let dueDate = task.dueDate {
                            Text(dueDate, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    CalendarBoardView(
        tasks: [
            ProjectTask(
                id: "1",
                projectBoardId: "board1",
                title: "Review design mockups",
                description: nil,
                status: .inProgress,
                priority: .high,
                assigneeIds: ["user1"],
                createdBy: "user1",
                dueDate: Date(),
                tags: ["Design"],
                dependencyIds: [],
                checklistItems: [],
                attachmentIds: [],
                createdAt: Date(),
                modifiedAt: Date()
            )
        ],
        onTaskTap: { _ in },
        onDateTap: { _ in }
    )
}
