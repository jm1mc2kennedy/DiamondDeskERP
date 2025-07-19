// AnalyticsService.swift
// Diamond Desk ERP
// Aggregates StoreReport and KPI data for dashboard KPIs/trends

import Foundation

final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    // Example: Aggregate WTD/MTD/YTD sales and KPI trends for a store
    func aggregateSales(_ reports: [StoreReportModel], for period: Calendar.Component) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let filtered = reports.filter { report in
            switch period {
            case .weekOfYear: return calendar.isDate(report.date, equalTo: now, toGranularity: .weekOfYear)
            case .month: return calendar.isDate(report.date, equalTo: now, toGranularity: .month)
            case .year: return calendar.isDate(report.date, equalTo: now, toGranularity: .year)
            default: return false
            }
        }
        return filtered.reduce(0) { $0 + $1.totalSales }
    }

    // Example: Compute average UPT, ADS, or other KPIs over a period
    func averageKPI(_ reports: [StoreReportModel], keyPath: KeyPath<StoreReportModel, Double>, for period: Calendar.Component) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let filtered = reports.filter { report in
            switch period {
            case .weekOfYear: return calendar.isDate(report.date, equalTo: now, toGranularity: .weekOfYear)
            case .month: return calendar.isDate(report.date, equalTo: now, toGranularity: .month)
            case .year: return calendar.isDate(report.date, equalTo: now, toGranularity: .year)
            default: return false
            }
        }
        guard !filtered.isEmpty else { return 0 }
        let total = filtered.reduce(0) { $0 + $1[keyPath: keyPath] }
        return total / Double(filtered.count)
    }
}
