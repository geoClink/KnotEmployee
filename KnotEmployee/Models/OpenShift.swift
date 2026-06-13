import Foundation

struct OpenShift: Identifiable, Hashable {
    enum Status: String { case open, offered, pending }
    let id = UUID()
    var offeredBy: String
    var day: String
    var date: String
    var start: String
    var end: String
    var role: String
    var reason: String? = nil
    var status: Status = .open
    var timeRange: String { "\(start) – \(end)" }
}
