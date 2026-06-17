import Foundation

struct Message: Identifiable, Hashable {
    let id = UUID()
    var senderName: String
    var text: String
    var timestamp: String
    var isFromCurrentUser: Bool
}

struct MessageThread: Identifiable, Hashable {
    let id = UUID()
    var participantName: String
    var lastMessage: String
    var timestamp: String
    var unread: Bool
    var messages: [Message]
    var isBroadcast: Bool = false
    var broadcastRecipientCount: Int = 0
}
