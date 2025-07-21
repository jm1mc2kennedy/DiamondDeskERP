import Foundation
import CloudKit

class Seeder {
    private let database: CKDatabase

    init(database: CKDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
    }

    func seedStores() async throws {
        let stores = try loadStoresFromJSON()
        
        for storeData in stores {
            let record = CKRecord(recordType: "Store")
            record["code"] = storeData.code as CKRecordValue
            record["name"] = storeData.name as CKRecordValue
            record["address"] = storeData.address as CKRecordValue
            record["status"] = storeData.status as CKRecordValue
            record["region"] = storeData.region as CKRecordValue
            
            try await database.save(record)
            print("Seeded store: \(storeData.name)")
        }
    }

    private func loadStoresFromJSON() throws -> [StoreSeed] {
        guard let url = Bundle.main.url(forResource: "SeedStores", withExtension: "json") else {
            fatalError("SeedStores.json not found")
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([StoreSeed].self, from: data)
    }
}

struct StoreSeed: Codable {
    let code: String
    let name: String
    let address: String
    let status: String
    let region: String
}
