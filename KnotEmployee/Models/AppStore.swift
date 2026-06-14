import Observation
import Foundation

enum ClockState { case out, clockedIn, onBreak }

struct LaborSummary {
    var actualToday: Int
    var scheduledToday: Int
    var forecastToday: Int
    var pctOfSales: Int
    var onClock: Int
    var scheduledCount: Int
}

struct ManagerAlert: Identifiable {
    enum Severity { case high, med, low }
    let id = UUID()
    var severity: Severity
    var text: String
}

@Observable final class AppStore {
    var currentUser: StaffMember
    var staff: [StaffMember]
    var shift: [Shift]
    var openShifts: [OpenShift]
    var swaps: [Swap]
    var timeOff: [TimeOff]
    
    var isManager: Bool { currentUser.role == .manager }
    
    var clockState: ClockState = .out
    var clockInAt: Date? = nil
    
    var labor = LaborSummary(actualToday: 388, scheduledToday: 412,
                             forecastToday: 430, pctOfSales: 27,
                             onClock: 4, scheduledCount: 6)
    
    var alerts: [ManagerAlert] = [
        ManagerAlert(severity: .high, text: "2 shifts unfilled Saturday"),
        ManagerAlert(severity: .med,  text: "Theo Brandt approaching overtime (38.5h)"),
        ManagerAlert(severity: .low,  text: "3 swap requests awaiting approval")
    ]
    
    var isAuthenticated = false
    
    // Mock auth — in production this is a backend call that returns the user + role.
    @discardableResult
    func signIn(pin: String) -> Bool {
        switch pin {
        case "1234":   // staff
            if let u = staff.first(where: { $0.name == "Maya Okafor" }) { currentUser = u }
            isAuthenticated = true
            return true
        case "0000":   // manager
            if let u = staff.first(where: { $0.role == .manager }) { currentUser = u }
            isAuthenticated = true
            return true
        default:
            return false
        }
    }

    func signOut() {
        isAuthenticated = false
    }

    init(currentUser: StaffMember, staff: [StaffMember], shift: [Shift], openShifts: [OpenShift], swaps: [Swap], timeOff: [TimeOff]) {
        self.currentUser = currentUser
        self.staff = staff
        self.shift = shift
        self.openShifts = openShifts
        self.swaps = swaps
        self.timeOff = timeOff
    }
}
