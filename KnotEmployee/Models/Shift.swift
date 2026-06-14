import Foundation

struct Shift: Identifiable, Hashable {
    enum Status { case scheduled, offered, swapped }
    let id = UUID()
    var day: String
    var date: String
    var start: String
    var end: String
    var role: String
    var note: String? = nil
    var breakLabel: String? = nil
    var status: Status = .scheduled
    var timeRange: String { "\(start) - \(end)" }
}
