//
//  MessageReadLog.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import Foundation
import CloudKit

/// Tracks explicit message read acknowledgments for enterprise reporting
/// Supports Store Ops-Center style read/completion tracking with multi-layer reporting
struct MessageReadLog: Identifiable, Codable {
    
    // MARK: - Properties
    
    let id: CKRecord.ID
    let messageId: String
    let userId: String
    let storeCode: String
    let timestamp: Date
    let readSource: ReadSource
    let deviceType: DeviceType
    
    // MARK: - Enums
    
    enum ReadSource: String, CaseIterable, Codable {
        case explicitOK = "explicit_ok"
        case autoMarked = "auto_marked"
        case adminOverride = "admin_override"
        
        var displayName: String {
            switch self {
            case .explicitOK: return "Explicit OK"
            case .autoMarked: return "Auto-marked"
            case .adminOverride: return "Admin Override"
            }
        }
    }
    
    enum DeviceType: String, CaseIterable, Codable {
        case iPhone = "iphone"
        case iPad = "ipad"
        case unknown = "unknown"
        
        var displayName: String {
            switch self {
            case .iPhone: return "iPhone"
            case .iPad: return "iPad"
            case .unknown: return "Unknown"
            }
        }
    }
    
    // MARK: - CloudKit Integration
    
    init?(record: CKRecord) {
        guard
            let messageId = record["messageId"] as? String,
            let userId = record["userId"] as? String,
            let storeCode = record["storeCode"] as? String,
            let timestamp = record["timestamp"] as? Date,
            let readSourceRaw = record["readSource"] as? String,
            let readSource = ReadSource(rawValue: readSourceRaw),
            let deviceTypeRaw = record["deviceType"] as? String,
            let deviceType = DeviceType(rawValue: deviceTypeRaw)
        else {
            return nil
        }
        
        self.id = record.recordID
        self.messageId = messageId
        self.userId = userId
        self.storeCode = storeCode
        self.timestamp = timestamp
        self.readSource = readSource
        self.deviceType = deviceType
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "MessageReadLog", recordID: id)
        record["messageId"] = messageId
        record["userId"] = userId
        record["storeCode"] = storeCode
        record["timestamp"] = timestamp
        record["readSource"] = readSource.rawValue
        record["deviceType"] = deviceType.rawValue
        return record
    }
    
    // MARK: - Convenience Initializers
    
    init(
        messageId: String,
        userId: String,
        storeCode: String,
        readSource: ReadSource = .explicitOK,
        deviceType: DeviceType = .iPhone
    ) {
        self.id = CKRecord.ID(zoneID: CKRecordZone.default().zoneID)
        self.messageId = messageId
        self.userId = userId
        self.storeCode = storeCode
        self.timestamp = Date()
        self.readSource = readSource
        self.deviceType = deviceType
    }
}

// MARK: - Reporting Extensions

extension MessageReadLog {
    
    /// Returns a formatted timestamp for reporting
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: timestamp)
    }
    
    /// Returns locale-specific CSV row data
    var csvRow: [String] {
        return [
            messageId,
            userId,
            storeCode,
            formattedTimestamp,
            readSource.displayName,
            deviceType.displayName
        ]
    }
    
    static var csvHeaders: [String] {
        return [
            "Message ID",
            "User ID", 
            "Store Code",
            "Timestamp",
            "Read Source",
            "Device Type"
        ]
    }
}

// MARK: - Hashable & Equatable

extension MessageReadLog: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MessageReadLog, rhs: MessageReadLog) -> Bool {
        return lhs.id == rhs.id
    }
}
