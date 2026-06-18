import Foundation

struct AppNotification: Identifiable, Hashable {
    enum Category { case shift, swap, timeOff, message, system }
    let id: UUID
    var icon: String
    var title: String
    var body: String
    var timestamp: String
    var isRead: Bool
    var category: Category
    var createdAt: Date

    init(id: UUID = UUID(), icon: String, title: String, body: String,
         timestamp: String, isRead: Bool, category: Category, createdAt: Date = Date()) {
        self.id = id; self.icon = icon; self.title = title; self.body = body
        self.timestamp = timestamp; self.isRead = isRead; self.category = category
        self.createdAt = createdAt
    }
}
