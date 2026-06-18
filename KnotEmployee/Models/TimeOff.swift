import Foundation

struct TimeOff: Identifiable, Hashable {
    enum Kind: String { case pto = "PTO", sick = "Sick", personal = "Personal" }
    enum Status: String { case pending, approved, denied }
    let id: UUID
    var staffName: String = ""
    var employeeId: UUID? = nil
    var kind: Kind
    var status: Status
    var range: String
    var days: Int
    var note: String? = nil
    var startDate: String = ""
    var endDate: String = ""

    init(id: UUID = UUID(), staffName: String = "", employeeId: UUID? = nil, kind: Kind,
         status: Status, range: String, days: Int, note: String? = nil,
         startDate: String = "", endDate: String = "") {
        self.id = id; self.staffName = staffName; self.employeeId = employeeId
        self.kind = kind; self.status = status; self.range = range
        self.days = days; self.note = note
        self.startDate = startDate; self.endDate = endDate
    }
}
