import Foundation

struct Swap: Identifiable, Hashable {
    enum Direction { case outgoing, incoming }
    enum Status: String { case pending, approved, denied }
    let id = UUID()
    var direction: Direction
    var status: Status
    var withName: String
}
