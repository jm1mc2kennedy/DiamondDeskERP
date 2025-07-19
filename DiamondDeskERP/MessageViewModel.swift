import SwiftUI
import Foundation
import CloudKit
internal import Combine

@MainActor
class MessageViewModel: ObservableObject {
    
    @Published var messages: [PublicMessage] = []
    @Published var isLoading = false

    private let database = CKContainer.default().publicCloudDatabase

    init() {
        NotificationCenter.default.addObserver(forName: .newMessageNotification, object: nil, queue: .main) { [weak self] _ in
            self?.fetchMessages()
        }
        subscribeToNewPosts()
    }

    func fetchMessages() {
        isLoading = true
        let query = CKQuery(recordType: "Post", predicate: NSPredicate(value: true))
        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        query.sortDescriptors = [sort]

        database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { result in
            Task { @MainActor in
                self.isLoading = false
                switch result {
                case .success(let (matchResults, _)):
                    let records = matchResults.compactMap { (_, matchResult) -> CKRecord? in
                        if case .success(let record) = matchResult {
                            return record
                        }
                        return nil
                    }
                    self.messages = records.map(PublicMessage.init)
                case .failure:
                    break // Optionally handle errors here
                }
            }
        }
    }

    func addMessage(title: String, author: String) {
        fetchUserRecordID { userRecordID in
            guard let userID = userRecordID else { return }

            let record = CKRecord(recordType: "Post")
            record["title"] = title as NSString
            record["author"] = author as NSString
            record["authorID"] = userID.recordName as NSString

            self.database.save(record) { _, _ in
                DispatchQueue.main.async {
                    self.fetchMessages()
                }
            }
        }
    }

    func deleteMessage(at offsets: IndexSet) {
        let messagesToDelete = offsets.map { self.messages[$0] }
        for message in messagesToDelete {
            database.delete(withRecordID: message.id) { _, _ in
                DispatchQueue.main.async {
                    self.fetchMessages()
                }
            }
        }
    }

    private func fetchUserRecordID(completion: @escaping (CKRecord.ID?) -> Void) {
        CKContainer.default().fetchUserRecordID { userRecordID, error in
            completion(userRecordID)
        }
    }
    
    func deleteMessageIfAuthorized(_ message: PublicMessage) {
        fetchUserRecordID { userRecordID in
            guard let userID = userRecordID?.recordName,
                  message.authorID == userID else {
                print("Unauthorized delete attempt.")
                return
            }

            self.database.delete(withRecordID: message.id) { _, _ in
                DispatchQueue.main.async {
                    self.fetchMessages()
                }
            }
        }
    }
    
    func subscribeToNewPosts() {
        let subscription = CKQuerySubscription(
            recordType: "Post",
            predicate: NSPredicate(value: true),
            subscriptionID: "new-posts-subscription",
            options: [.firesOnRecordCreation]
        )

        let info = CKSubscription.NotificationInfo()
        info.alertBody = "A new message was posted!"
        info.shouldBadge = true
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info

        database.save(subscription) { result, error in
            if let error = error {
                print("Subscription error: \(error)")
            } else {
                print("Subscribed to new messages.")
            }
        }
    }
}

import Foundation

extension Notification.Name {
    static let newMessageNotification = Notification.Name("newMessageNotification")
}
