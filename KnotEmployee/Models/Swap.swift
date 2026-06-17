import Foundation

struct Swap: Identifiable, Hashable {
    enum Direction { case outgoing, incoming }
    enum Status: String { case pending, approved, denied }
    let id: UUID
    var fromName: String = ""
    var direction: Direction
    var status: Status
    var withName: String

    init(id: UUID = UUID(), fromName: String = "", direction: Direction,
         status: Status, withName: String) {
        self.id = id; self.fromName = fromName
        self.direction = direction; self.status = status; self.withName = withName
    }
}
