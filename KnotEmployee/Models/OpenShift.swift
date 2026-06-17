import Foundation

struct OpenShift: Identifiable, Hashable {
    enum Status: String { case open, pending, approved }
    let id: UUID
    var offeredBy: String
    var day: String
    var date: String
    var start: String
    var end: String
    var role: String
    var reason: String? = nil
    var status: Status = .open
    var timeRange: String { "\(start) – \(end)" }

    init(id: UUID = UUID(), offeredBy: String, day: String, date: String,
         start: String, end: String, role: String,
         reason: String? = nil, status: Status = .open) {
        self.id = id; self.offeredBy = offeredBy; self.day = day
        self.date = date; self.start = start; self.end = end
        self.role = role; self.reason = reason; self.status = status
    }
}
