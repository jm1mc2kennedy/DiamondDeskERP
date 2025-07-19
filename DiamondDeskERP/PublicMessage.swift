import CloudKit

struct PublicMessage: Identifiable {
    let id: CKRecord.ID
    let title: String
    let author: String
    let authorID: String?

    init(record: CKRecord) {
        self.id = record.recordID
        self.title = record["title"] as? String ?? "(No Title)"
        self.author = record["author"] as? String ?? "Anonymous"
        self.authorID = record["authorID"] as? String
    }
}
