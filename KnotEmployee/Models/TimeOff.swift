import Foundation

struct TimeOff: Identifiable, Hashable {
    enum Kind: String { case pto = "PTO", sick = "Sick", personal = "Personal" }
    enum Status: String { case pending, approved, denied }
    let id: UUID
    var staffName: String = ""
    var kind: Kind
    var status: Status
    var range: String
    var days: Int
    var note: String? = nil

    init(id: UUID = UUID(), staffName: String = "", kind: Kind,
         status: Status, range: String, days: Int, note: String? = nil) {
        self.id = id; self.staffName = staffName; self.kind = kind
        self.status = status; self.range = range; self.days = days; self.note = note
    }
}
