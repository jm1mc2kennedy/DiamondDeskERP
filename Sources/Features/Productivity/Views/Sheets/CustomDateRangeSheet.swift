//
//  CustomDateRangeSheet.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI

struct CustomDateRangeSheet: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isPresented: Bool
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var tempStartDate: Date
    @State private var tempEndDate: Date
    @State private var selectedPreset: DateRangePreset?
    
    init(startDate: Binding<Date>, endDate: Binding<Date>, isPresented: Binding<Bool>) {
        self._startDate = startDate
        self._endDate = endDate
        self._isPresented = isPresented
        self._tempStartDate = State(initialValue: startDate.wrappedValue)
        self._tempEndDate = State(initialValue: endDate.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Quick Presets
                presetsSection
                
                Divider()
                
                // Custom Date Selection
                customDateSection
            }
            .navigationTitle("Select Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        startDate = tempStartDate
                        endDate = tempEndDate
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValidDateRange)
                }
            }
        }
    }
    
    // MARK: - Content Views
    
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Select")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DateRangePreset.allCases, id: \.self) { preset in
                        PresetButton(
                            preset: preset,
                            isSelected: selectedPreset == preset,
                            action: {
                                selectedPreset = preset
                                let (start, end) = preset.dateRange
                                tempStartDate = start
                                tempEndDate = end
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
    }
    
    private var customDateSection: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Custom Range")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if let preset = selectedPreset {
                        Button("Clear") {
                            selectedPreset = nil
                        }
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    }
                }
                
                // Date pickers
                VStack(spacing: 16) {
                    DatePickerRow(
                        title: "From",
                        date: $tempStartDate,
                        isStartDate: true
                    )
                    
                    DatePickerRow(
                        title: "To",
                        date: $tempEndDate,
                        minimumDate: tempStartDate,
                        isStartDate: false
                    )
                }
                
                // Date range summary
                if isValidDateRange {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Selected Range")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(daysBetween) day\(daysBetween == 1 ? "" : "s")")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        Text(dateRangeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Computed Properties
    
    private var isValidDateRange: Bool {
        tempStartDate <= tempEndDate
    }
    
    private var daysBetween: Int {
        Calendar.current.dateComponents([.day], from: tempStartDate, to: tempEndDate).day ?? 0
    }
    
    private var dateRangeDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let startString = formatter.string(from: tempStartDate)
        let endString = formatter.string(from: tempEndDate)
        
        return "\(startString) to \(endString)"
    }
}

// MARK: - Preset Button

struct PresetButton: View {
    let preset: DateRangePreset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(preset.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(preset.subtitle)
                    .font(.caption2)
                    .opacity(0.8)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color(.systemGray6))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Date Picker Row

struct DatePickerRow: View {
    let title: String
    @Binding var date: Date
    var minimumDate: Date?
    let isStartDate: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            DatePicker(
                "",
                selection: $date,
                in: dateRange,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var dateRange: PartialRangeFrom<Date> {
        if let minimumDate = minimumDate {
            return minimumDate...
        } else {
            return Date.distantPast...
        }
    }
}

// MARK: - Date Range Presets

enum DateRangePreset: CaseIterable {
    case today
    case yesterday
    case thisWeek
    case lastWeek
    case thisMonth
    case lastMonth
    case thisQuarter
    case lastQuarter
    case thisYear
    case last30Days
    case last90Days
    case last6Months
    
    var title: String {
        switch self {
        case .today:
            return "Today"
        case .yesterday:
            return "Yesterday"
        case .thisWeek:
            return "This Week"
        case .lastWeek:
            return "Last Week"
        case .thisMonth:
            return "This Month"
        case .lastMonth:
            return "Last Month"
        case .thisQuarter:
            return "This Quarter"
        case .lastQuarter:
            return "Last Quarter"
        case .thisYear:
            return "This Year"
        case .last30Days:
            return "Last 30 Days"
        case .last90Days:
            return "Last 90 Days"
        case .last6Months:
            return "Last 6 Months"
        }
    }
    
    var subtitle: String {
        let (start, end) = dateRange
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let calendar = Calendar.current
        
        if calendar.isDate(start, inSameDayAs: end) {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: start)
        } else if calendar.isDate(start, equalTo: end, toGranularity: .year) {
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            let startString = formatter.string(from: start)
            formatter.dateFormat = "MMM d, yyyy"
            let endString = formatter.string(from: end)
            return "\(startString) - \(endString)"
        }
    }
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
            
        case .yesterday:
            let today = calendar.startOfDay(for: now)
            let start = calendar.date(byAdding: .day, value: -1, to: today)!
            return (start, today)
            
        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return (start, end)
            
        case .lastWeek:
            let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let start = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart)!
            return (start, thisWeekStart)
            
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
            
        case .lastMonth:
            let thisMonthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
            return (start, thisMonthStart)
            
        case .thisQuarter:
            let currentQuarter = (calendar.component(.month, from: now) - 1) / 3
            let startMonth = currentQuarter * 3 + 1
            var components = calendar.dateComponents([.year], from: now)
            components.month = startMonth
            components.day = 1
            let start = calendar.date(from: components)!
            let end = calendar.date(byAdding: .month, value: 3, to: start)!
            return (start, end)
            
        case .lastQuarter:
            let currentQuarter = (calendar.component(.month, from: now) - 1) / 3
            let lastQuarterStartMonth = ((currentQuarter - 1 + 4) % 4) * 3 + 1
            var components = calendar.dateComponents([.year], from: now)
            if currentQuarter == 0 {
                components.year = (components.year ?? 0) - 1
            }
            components.month = lastQuarterStartMonth
            components.day = 1
            let start = calendar.date(from: components)!
            let end = calendar.date(byAdding: .month, value: 3, to: start)!
            return (start, end)
            
        case .thisYear:
            let start = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return (start, end)
            
        case .last30Days:
            let end = calendar.startOfDay(for: now)
            let start = calendar.date(byAdding: .day, value: -30, to: end)!
            return (start, end)
            
        case .last90Days:
            let end = calendar.startOfDay(for: now)
            let start = calendar.date(byAdding: .day, value: -90, to: end)!
            return (start, end)
            
        case .last6Months:
            let end = calendar.startOfDay(for: now)
            let start = calendar.date(byAdding: .month, value: -6, to: end)!
            return (start, end)
        }
    }
}

#Preview {
    CustomDateRangeSheet(
        startDate: .constant(Date()),
        endDate: .constant(Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()),
        isPresented: .constant(true)
    )
}
