//
//  CreatePersonalTodoSheet.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/21/25.
//

import SwiftUI

struct CreatePersonalTodoSheet: View {
    let viewModel: ProductivityViewModel
    
    @State private var title = ""
    @State private var notes = ""
    @State private var priority: TaskPriority = .medium
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var isRecurring = false
    @State private var recurringPattern: RecurringPattern = .daily
    @State private var selectedTags: Set<String> = []
    @State private var reminderEnabled = false
    @State private var reminderTime: Date = Date()
    @State private var estimatedDuration: TimeInterval?
    @State private var hasEstimatedDuration = false
    @State private var categoryTag = ""
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @FocusState private var titleFieldFocused: Bool
    
    @State private var isCreating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var popularTags: [String] {
        ["Work", "Personal", "Health", "Shopping", "Finance", "Learning", "Family", "Exercise", "Travel", "Hobby"]
    }
    
    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                priorityAndCategorySection
                dueDateSection
                reminderSection
                recurringSection
                durationSection
                tagsSection
                notesSection
            }
            .navigationTitle("New Personal To-Do")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await createTodo()
                        }
                    }
                    .disabled(!isValid || isCreating)
                }
            }
            .onAppear {
                titleFieldFocused = true
            }
            .alert("Error Creating To-Do", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Form Sections
    
    private var basicInfoSection: some View {
        Section("Basic Information") {
            VStack(alignment: .leading, spacing: 8) {
                TextField("What needs to be done?", text: $title, axis: .vertical)
                    .focused($titleFieldFocused)
                    .lineLimit(1...3)
                    .accessibilityLabel("To-do title")
                
                if dynamicTypeSize.isAccessibilitySize {
                    Text("Enter a clear, actionable description")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var priorityAndCategorySection: some View {
        Section("Priority & Category") {
            Picker("Priority", selection: $priority) {
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    HStack {
                        priorityIcon(priority)
                        Text(priority.displayName)
                    }
                    .tag(priority)
                }
            }
            .pickerStyle(.segmented)
            
            HStack {
                Image(systemName: "tag")
                    .foregroundColor(.accentColor)
                TextField("Category (optional)", text: $categoryTag)
                    .textInputAutocapitalization(.words)
            }
        }
    }
    
    private var dueDateSection: some View {
        Section("Due Date") {
            Toggle("Set Due Date", isOn: $hasDueDate)
            
            if hasDueDate {
                DatePicker(
                    "Due Date",
                    selection: Binding(
                        get: { dueDate ?? Date() },
                        set: { dueDate = $0 }
                    ),
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
            }
        }
    }
    
    private var reminderSection: some View {
        Section("Reminders") {
            Toggle("Enable Reminder", isOn: $reminderEnabled)
            
            if reminderEnabled && hasDueDate {
                DatePicker(
                    "Reminder Time",
                    selection: $reminderTime,
                    in: Date()...(dueDate ?? Date()),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
            } else if reminderEnabled && !hasDueDate {
                Text("Set a due date to enable reminders")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var recurringSection: some View {
        Section("Recurring") {
            Toggle("Repeat This To-Do", isOn: $isRecurring)
            
            if isRecurring {
                Picker("Repeat Pattern", selection: $recurringPattern) {
                    ForEach(RecurringPattern.allCases, id: \.self) { pattern in
                        Text(pattern.displayName).tag(pattern)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    private var durationSection: some View {
        Section("Estimated Duration") {
            Toggle("Set Estimated Duration", isOn: $hasEstimatedDuration)
            
            if hasEstimatedDuration {
                DurationPicker(duration: Binding(
                    get: { estimatedDuration ?? 900 }, // Default 15 minutes
                    set: { estimatedDuration = $0 }
                ))
            }
        }
    }
    
    private var tagsSection: some View {
        Section("Tags") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(popularTags, id: \.self) { tag in
                    TagChip(
                        tag: tag,
                        isSelected: selectedTags.contains(tag)
                    ) {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }
                }
            }
            
            if !categoryTag.isEmpty && !popularTags.contains(categoryTag) {
                TagChip(
                    tag: categoryTag,
                    isSelected: selectedTags.contains(categoryTag)
                ) {
                    if selectedTags.contains(categoryTag) {
                        selectedTags.remove(categoryTag)
                    } else {
                        selectedTags.insert(categoryTag)
                    }
                }
            }
        }
    }
    
    private var notesSection: some View {
        Section("Additional Notes") {
            TextField("Optional notes or details...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    // MARK: - Helper Methods
    
    private func priorityIcon(_ priority: TaskPriority) -> some View {
        Image(systemName: priority.iconName)
            .foregroundColor(priority.color)
    }
    
    private func createTodo() async {
        guard isValid else { return }
        
        isCreating = true
        defer { isCreating = false }
        
        do {
            await viewModel.createPersonalTodo(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.isEmpty ? "" : notes.trimmingCharacters(in: .whitespacesAndNewlines),
                dueDate: hasDueDate ? dueDate : nil,
                priority: priority,
                recurringPattern: isRecurring ? recurringPattern : nil
            )
            
            dismiss()
            
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Supporting Components

struct DurationPicker: View {
    @Binding var duration: TimeInterval
    
    private let hours: Int
    private let minutes: Int
    
    init(duration: Binding<TimeInterval>) {
        self._duration = duration
        let totalMinutes = Int(duration.wrappedValue / 60)
        self.hours = totalMinutes / 60
        self.minutes = totalMinutes % 60
    }
    
    var body: some View {
        HStack {
            Picker("Hours", selection: Binding(
                get: { hours },
                set: { newHours in
                    duration = TimeInterval((newHours * 60 + minutes) * 60)
                }
            )) {
                ForEach(0..<24) { hour in
                    Text("\(hour)h").tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80)
            
            Picker("Minutes", selection: Binding(
                get: { minutes },
                set: { newMinutes in
                    duration = TimeInterval((hours * 60 + newMinutes) * 60)
                }
            )) {
                ForEach(Array(stride(from: 0, to: 60, by: 15))) { minute in
                    Text("\(minute)m").tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80)
        }
    }
}

struct TagChip: View {
    let tag: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(tag)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Extensions for TaskPriority

extension TaskPriority {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var iconName: String {
        switch self {
        case .low: return "minus.circle"
        case .medium: return "equal.circle"
        case .high: return "plus.circle"
        case .urgent: return "exclamationmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - RecurringPattern Extension

extension RecurringPattern {
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Preview

#Preview {
    CreatePersonalTodoSheet(viewModel: ProductivityViewModel())
}
