import Foundation

struct Shift: Identifiable, Hashable {
    enum Status: String { case scheduled, offered, swapped }
    let id: UUID
    var day: String
    var date: String
    var shiftDate: String = ""
    var start: String
    var end: String
    var role: String
    var note: String? = nil
    var breakLabel: String? = nil
    var status: Status = .scheduled
    var timeRange: String { "\(start) - \(end)" }

    init(id: UUID = UUID(), day: String, date: String, shiftDate: String = "",
         start: String, end: String, role: String, note: String? = nil,
         breakLabel: String? = nil, status: Status = .scheduled) {
        self.id = id; self.day = day; self.date = date; self.shiftDate = shiftDate
        self.start = start; self.end = end; self.role = role
        self.note = note; self.breakLabel = breakLabel; self.status = status
    }
}
