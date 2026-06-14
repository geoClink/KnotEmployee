import Foundation

struct TimeOff: Identifiable, Hashable {
    enum kind: String { case pto = "PTO", sick = "Sick", personal = "Personal" }
    enum Status: String { case pending, approved, denied }
    let id = UUID()
    var staffName: String = ""
    var kind: kind
    var status: Status
    var range: String
    var days: Int
    var note: String? = nil
}
