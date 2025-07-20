// KPIModel.swift
// Diamond Desk ERP
// Domain model and CloudKit mapping for KPI (KPIRecord)

import Foundation
import CloudKit

struct KPIModel: Identifiable, Hashable {
    let id: CKRecord.ID
    var date: Date
    var storeCode: String
    var metrics: [String: Double]
    
    // MARK: - Cache Enhancement Fields (Per Buildout Plan)
    var isCacheRecord: Bool // Indicates if this is a cached aggregation
    var cacheExpiresAt: Date? // When this cache record expires
    var sourceDataHash: String? // Hash of source data for cache validation
    var aggregationPeriod: KPIAggregationPeriod? // What period this cache represents
    var calculatedAt: Date? // When the aggregation was calculated
    var cacheVersion: String? // Cache schema version for migrations
    var sourceRecordCount: Int? // Number of source records aggregated
    var cacheMetadata: KPICacheMetadata?
    
    enum KPIAggregationPeriod: String, CaseIterable, Codable {
        case daily = "daily"
        case weekly = "weekly" 
        case monthly = "monthly"
        case quarterly = "quarterly"
        case yearly = "yearly"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .quarterly: return "Quarterly"
            case .yearly: return "Yearly"
            case .custom: return "Custom Period"
            }
        }
        
        var defaultCacheDuration: TimeInterval {
            switch self {
            case .daily: return 24 * 60 * 60 // 24 hours
            case .weekly: return 7 * 24 * 60 * 60 // 7 days
            case .monthly: return 30 * 24 * 60 * 60 // 30 days
            case .quarterly: return 90 * 24 * 60 * 60 // 90 days
            case .yearly: return 365 * 24 * 60 * 60 // 365 days
            case .custom: return 24 * 60 * 60 // Default to 24 hours
            }
        }
    }
    
    struct KPICacheMetadata: Codable, Hashable {
        let sourceTypes: [String] // Types of records that contributed to this cache
        let calculationMethod: String // How the aggregation was calculated
        let lastValidated: Date // Last time cache was validated against source
        let confidence: Double // Confidence level in the cached data (0.0-1.0)
        let partialData: Bool // Whether this represents partial data
        let dataQualityScore: Double // Quality score of source data (0.0-1.0)
        let refreshStrategy: CacheRefreshStrategy
        let dependencies: [String]? // Other cache records this depends on
        
        enum CacheRefreshStrategy: String, Codable {
            case manual = "manual"
            case scheduled = "scheduled"
            case onDemand = "on_demand"
            case realTime = "real_time"
            case eventDriven = "event_driven"
        }
    }
    
    // MARK: - Initializers
    
    init(
        id: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString),
        date: Date,
        storeCode: String,
        metrics: [String: Double],
        isCacheRecord: Bool = false,
        cacheExpiresAt: Date? = nil,
        sourceDataHash: String? = nil,
        aggregationPeriod: KPIAggregationPeriod? = nil,
        calculatedAt: Date? = nil,
        cacheVersion: String? = nil,
        sourceRecordCount: Int? = nil,
        cacheMetadata: KPICacheMetadata? = nil
    ) {
        self.id = id
        self.date = date
        self.storeCode = storeCode
        self.metrics = metrics
        self.isCacheRecord = isCacheRecord
        self.cacheExpiresAt = cacheExpiresAt
        self.sourceDataHash = sourceDataHash
        self.aggregationPeriod = aggregationPeriod
        self.calculatedAt = calculatedAt
        self.cacheVersion = cacheVersion
        self.sourceRecordCount = sourceRecordCount
        self.cacheMetadata = cacheMetadata
    }
}

extension KPIModel {
    init?(record: CKRecord) {
        guard let date = record["date"] as? Date,
              let storeCode = record["storeCode"] as? String,
              let metricsData = record["metrics"] as? Data,
              let metrics = try? JSONDecoder().decode([String: Double].self, from: metricsData)
        else { return nil }
        
        self.id = record.recordID
        self.date = date
        self.storeCode = storeCode
        self.metrics = metrics
        
        // Cache enhancement fields
        self.isCacheRecord = record["isCacheRecord"] as? Bool ?? false
        self.cacheExpiresAt = record["cacheExpiresAt"] as? Date
        self.sourceDataHash = record["sourceDataHash"] as? String
        self.calculatedAt = record["calculatedAt"] as? Date
        self.cacheVersion = record["cacheVersion"] as? String
        self.sourceRecordCount = record["sourceRecordCount"] as? Int
        
        // Decode aggregation period
        if let periodRaw = record["aggregationPeriod"] as? String {
            self.aggregationPeriod = KPIAggregationPeriod(rawValue: periodRaw)
        } else {
            self.aggregationPeriod = nil
        }
        
        // Decode cache metadata
        if let metadataData = record["cacheMetadata"] as? Data,
           let metadata = try? JSONDecoder().decode(KPICacheMetadata.self, from: metadataData) {
            self.cacheMetadata = metadata
        } else {
            self.cacheMetadata = nil
        }
    }

    func toRecord() -> CKRecord {
        let rec = CKRecord(recordType: "KPIRecord", recordID: id)
        rec["date"] = date as CKRecordValue
        rec["storeCode"] = storeCode as CKRecordValue
        
        // Encode metrics
        let metricsData = try? JSONEncoder().encode(metrics)
        rec["metrics"] = metricsData as CKRecordValue?
        
        // Cache enhancement fields
        rec["isCacheRecord"] = isCacheRecord as CKRecordValue
        rec["cacheExpiresAt"] = cacheExpiresAt as CKRecordValue?
        rec["sourceDataHash"] = sourceDataHash as CKRecordValue?
        rec["calculatedAt"] = calculatedAt as CKRecordValue?
        rec["cacheVersion"] = cacheVersion as CKRecordValue?
        rec["sourceRecordCount"] = sourceRecordCount as CKRecordValue?
        rec["aggregationPeriod"] = aggregationPeriod?.rawValue as CKRecordValue?
        
        // Encode cache metadata
        if let metadata = cacheMetadata,
           let metadataData = try? JSONEncoder().encode(metadata) {
            rec["cacheMetadata"] = metadataData as CKRecordValue?
        }
        
        return rec
    }
    
    // MARK: - Cache Management Methods
    
    /// Create a cache record from aggregated data
    static func createCache(
        date: Date,
        storeCode: String,
        metrics: [String: Double],
        aggregationPeriod: KPIAggregationPeriod,
        sourceRecordCount: Int,
        sourceDataHash: String,
        metadata: KPICacheMetadata? = nil
    ) -> KPIModel {
        let cacheExpiration = Date().addingTimeInterval(aggregationPeriod.defaultCacheDuration)
        
        return KPIModel(
            date: date,
            storeCode: storeCode,
            metrics: metrics,
            isCacheRecord: true,
            cacheExpiresAt: cacheExpiration,
            sourceDataHash: sourceDataHash,
            aggregationPeriod: aggregationPeriod,
            calculatedAt: Date(),
            cacheVersion: "1.0",
            sourceRecordCount: sourceRecordCount,
            cacheMetadata: metadata
        )
    }
    
    /// Check if cache is expired
    var isCacheExpired: Bool {
        guard isCacheRecord, let expiresAt = cacheExpiresAt else { return false }
        return Date() > expiresAt
    }
    
    /// Check if cache is valid (not expired and has valid hash)
    var isCacheValid: Bool {
        guard isCacheRecord else { return true } // Non-cache records are always valid
        return !isCacheExpired && sourceDataHash != nil
    }
    
    /// Extend cache expiration
    func withExtendedExpiration(duration: TimeInterval) -> KPIModel {
        guard isCacheRecord else { return self }
        
        var updated = self
        updated.cacheExpiresAt = Date().addingTimeInterval(duration)
        return updated
    }
    
    /// Update cache with new data
    func withUpdatedMetrics(
        _ newMetrics: [String: Double],
        sourceRecordCount: Int,
        sourceDataHash: String
    ) -> KPIModel {
        guard isCacheRecord else { return self }
        
        var updated = self
        updated.metrics = newMetrics
        updated.sourceRecordCount = sourceRecordCount
        updated.sourceDataHash = sourceDataHash
        updated.calculatedAt = Date()
        
        // Reset expiration based on aggregation period
        if let period = aggregationPeriod {
            updated.cacheExpiresAt = Date().addingTimeInterval(period.defaultCacheDuration)
        }
        
        return updated
    }
    
    /// Invalidate cache
    func invalidated() -> KPIModel {
        guard isCacheRecord else { return self }
        
        var updated = self
        updated.cacheExpiresAt = Date() // Expire immediately
        return updated
    }
    
    // MARK: - Computed Properties
    
    /// Time until cache expires
    var timeUntilExpiration: TimeInterval? {
        guard isCacheRecord, let expiresAt = cacheExpiresAt else { return nil }
        return expiresAt.timeIntervalSinceNow
    }
    
    /// Cache age (time since calculated)
    var cacheAge: TimeInterval? {
        guard isCacheRecord, let calculatedAt = calculatedAt else { return nil }
        return Date().timeIntervalSince(calculatedAt)
    }
    
    /// Cache efficiency score (0.0 to 1.0)
    var cacheEfficiencyScore: Double? {
        guard isCacheRecord,
              let sourceCount = sourceRecordCount,
              let metadata = cacheMetadata else { return nil }
        
        // Simple efficiency calculation based on data quality and source count
        let sourceCountScore = min(1.0, Double(sourceCount) / 100.0) // Max score at 100+ sources
        let qualityScore = metadata.dataQualityScore
        let confidenceScore = metadata.confidence
        
        return (sourceCountScore + qualityScore + confidenceScore) / 3.0
    }
}
