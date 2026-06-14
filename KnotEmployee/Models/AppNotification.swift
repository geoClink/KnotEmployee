import Foundation

struct AppNotification: Identifiable, Hashable {
    enum Category { case shift, swap, timeOff, message, system }
    let id = UUID()
    var icon: String
    var title: String
    var body: String
    var timestamp: String
    var isRead: Bool
    var category: Category
}
