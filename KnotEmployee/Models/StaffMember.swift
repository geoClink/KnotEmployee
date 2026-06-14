import Foundation

struct StaffMember: Identifiable, Hashable {
    enum Role: String { case staff, manager }
    let id = UUID()
    var name: String
    var jobTitle: String
    var role: Role = .staff
    var hoursThisWeek: Double = 0
    var hourlyRate: Double = 0
    var clockStatus: ClockState = .out
}
