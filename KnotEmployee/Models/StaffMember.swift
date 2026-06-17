import Foundation

struct StaffMember: Identifiable, Hashable {
    enum Role: String { case staff, manager }
    let id: UUID
    var name: String
    var jobTitle: String
    var role: Role = .staff
    var hoursThisWeek: Double = 0
    var hourlyRate: Double = 0
    var clockStatus: ClockState = .out
    var userId: UUID? = nil

    init(id: UUID = UUID(), name: String, jobTitle: String,
         role: Role = .staff, hoursThisWeek: Double = 0,
         hourlyRate: Double = 0, clockStatus: ClockState = .out,
         userId: UUID? = nil) {
        self.id = id; self.name = name; self.jobTitle = jobTitle
        self.role = role; self.hoursThisWeek = hoursThisWeek
        self.hourlyRate = hourlyRate; self.clockStatus = clockStatus
        self.userId = userId
    }

    static let placeholder = StaffMember(name: "", jobTitle: "")
}
