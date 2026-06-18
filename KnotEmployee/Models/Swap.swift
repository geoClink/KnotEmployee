import Foundation

struct Swap: Identifiable, Hashable {
    enum Direction { case outgoing, incoming }
    enum Status: String { case pending, approved, denied }
    let id: UUID
    var fromName: String = ""
    var direction: Direction
    var status: Status
    var withName: String
    var fromShiftId: UUID? = nil
    var withEmployeeId: UUID? = nil

    init(id: UUID = UUID(), fromName: String = "", direction: Direction,
         status: Status, withName: String,
         fromShiftId: UUID? = nil, withEmployeeId: UUID? = nil) {
        self.id = id; self.fromName = fromName
        self.direction = direction; self.status = status; self.withName = withName
        self.fromShiftId = fromShiftId; self.withEmployeeId = withEmployeeId
    }
}
