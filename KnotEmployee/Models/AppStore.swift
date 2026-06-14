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

struct ScheduleRow: Identifiable {
    let id = UUID()
    var name: String
    var cells: [String?]   // 7 entries (Mon–Sun); nil = off
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
    var threads: [MessageThread]
    var notifications: [AppNotification]
    
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
    
    var weekGrid: [ScheduleRow] = [
        ScheduleRow(name: "Maya Okafor",  cells: ["6–2", nil, "6–2", "7–3", "6–12", nil, "7–1"]),
        ScheduleRow(name: "Devon Hale",   cells: ["7–3", "7–3", nil, nil, "12–8", "12–8", nil]),
        ScheduleRow(name: "Priya Raman",  cells: [nil, "8–4", "8–4", "8–4", nil, "9–5", "9–5"]),
        ScheduleRow(name: "Theo Brandt",  cells: ["5–1", "5–1", "5–1", "5–1", "5–1", nil, nil]),
        ScheduleRow(name: "Aisha Bello",  cells: [nil, "2–9", "2–9", nil, nil, "2–9", "2–9"]),
        ScheduleRow(name: "Jonah Klein",  cells: ["3–9", nil, "3–9", "3–9", "3–9", "4–10", nil])
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

    init(currentUser: StaffMember, staff: [StaffMember], shift: [Shift], openShifts: [OpenShift], swaps: [Swap], timeOff: [TimeOff], threads: [MessageThread] = [], notifications: [AppNotification] = []) {
        self.currentUser = currentUser
        self.staff = staff
        self.shift = shift
        self.openShifts = openShifts
        self.swaps = swaps
        self.timeOff = timeOff
        self.threads = threads
        self.notifications = notifications
    }
}
