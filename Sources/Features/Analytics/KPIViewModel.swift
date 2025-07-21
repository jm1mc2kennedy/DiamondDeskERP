import Foundation
import CloudKit
import Combine

struct KPIData {
    var totalSales: Double = 0
    var averageADS: Double = 0
    var averageUPT: Double = 0
    var totalTransactions: Int = 0
}

@MainActor
class KPIViewModel: ObservableObject {
    @Published var kpiData = KPIData()
    @Published var error: Error?
    @Published var isLoading: Bool = false
    
    private let database: CKDatabase
    
    init(database: CKDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
    }
    
    func fetchKPIs(for storeCode: String, timePeriod: TimePeriod = .mtd) {
        isLoading = true
        
        let (startDate, _) = timePeriod.dateRange()
        
        let predicate = NSPredicate(format: "storeCode == %@ AND date >= %@", storeCode, startDate as NSDate)
        let query = CKQuery(recordType: "StoreReport", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.error = error
                    return
                }
                
                let reports = records?.compactMap { StoreReportModel(record: $0) } ?? []
                self.calculateKPIs(from: reports)
            }
        }
    }
    
    private func calculateKPIs(from reports: [StoreReportModel]) {
        let totalSales = reports.reduce(0) { $0 + $1.totalSales }
        let totalTransactions = reports.reduce(0) { $0 + $1.totalTransactions }
        let totalItems = reports.reduce(0) { $0 + $1.totalItems }
        
        let averageADS = totalTransactions > 0 ? totalSales / Double(totalTransactions) : 0
        let averageUPT = totalTransactions > 0 ? Double(totalItems) / Double(totalTransactions) : 0
        
        self.kpiData = KPIData(totalSales: totalSales, averageADS: averageADS, averageUPT: averageUPT, totalTransactions: totalTransactions)
    }
}

enum TimePeriod: String, CaseIterable, Identifiable {
    case wtd = "WTD"
    case mtd = "MTD"
    case ytd = "YTD"
    
    var id: String { self.rawValue }
    
    func dateRange() -> (start: Date, end: Date) {
        let now = Date()
        let calendar = Calendar.current
        
        switch self {
        case .wtd:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return (startOfWeek, now)
        case .mtd:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return (startOfMonth, now)
        case .ytd:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            return (startOfYear, now)
        }
    }
}
