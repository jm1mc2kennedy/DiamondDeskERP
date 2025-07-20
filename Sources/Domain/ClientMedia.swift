import Foundation
import CloudKit

enum ClientMediaType: String, Codable, CaseIterable, Identifiable {
    case photo = "photo"
    case drawing = "drawing"
    case document = "doc"
    
    var id: String { self.rawValue }
}

struct ClientMedia: Identifiable, Hashable {
    let id: CKRecord.ID
    var clientRef: CKRecord.Reference
    var type: ClientMediaType
    var asset: CKAsset
    var uploadedByRef: CKRecord.Reference
    var createdAt: Date
    var caption: String?
    
    init?(record: CKRecord) {
        guard
            let clientRef = record["clientRef"] as? CKRecord.Reference,
            let typeRaw = record["type"] as? String,
            let type = ClientMediaType(rawValue: typeRaw),
            let asset = record["asset"] as? CKAsset,
            let uploadedByRef = record["uploadedByRef"] as? CKRecord.Reference,
            let createdAt = record["createdAt"] as? Date
        else {
            return nil
        }
        
        self.id = record.recordID
        self.clientRef = clientRef
        self.type = type
        self.asset = asset
        self.uploadedByRef = uploadedByRef
        self.createdAt = createdAt
        self.caption = record["caption"] as? String
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "ClientMedia", recordID: id)
        record["clientRef"] = clientRef as CKRecordValue
        record["type"] = type.rawValue as CKRecordValue
        record["asset"] = asset as CKRecordValue
        record["uploadedByRef"] = uploadedByRef as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        if let caption = caption {
            record["caption"] = caption as CKRecordValue
        }
        return record
    }
    
    static func from(record: CKRecord) -> ClientMedia? {
        return ClientMedia(record: record)
    }
}
