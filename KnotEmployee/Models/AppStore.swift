import Observation
import Foundation
import Supabase

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
    enum Destination { case schedule, labor, approvals, timeOff }
    let id = UUID()
    var severity: Severity
    var text: String
    var destination: Destination
}

@Observable @MainActor final class AppStore {
    var currentUser: StaffMember
    var staff: [StaffMember]
    var shift: [Shift]
    var openShifts: [OpenShift]
    var swaps: [Swap]
    var timeOff: [TimeOff]
    var threads: [MessageThread]
    var notifications: [AppNotification]

    var isAuthenticated = false
    var isLoading = false
    var authError: String? = nil

    var isManager: Bool { currentUser.role == .manager }

    var clockState: ClockState = .out
    var clockInAt: Date? = nil

    var labor = LaborSummary(actualToday: 388, scheduledToday: 412,
                             forecastToday: 430, pctOfSales: 27,
                             onClock: 4, scheduledCount: 6)

    var alerts: [ManagerAlert] = [
        ManagerAlert(severity: .high, text: "2 shifts unfilled Saturday",              destination: .schedule),
        ManagerAlert(severity: .med,  text: "Theo Brandt approaching overtime (38.5h)", destination: .labor),
        ManagerAlert(severity: .low,  text: "3 swap requests awaiting approval",        destination: .approvals)
    ]

    var weekGrid: [ScheduleRow] = [
        ScheduleRow(name: "Maya Okafor",  cells: ["6–2", nil, "6–2", "7–3", "6–12", nil, "7–1"]),
        ScheduleRow(name: "Devon Hale",   cells: ["7–3", "7–3", nil, nil, "12–8", "12–8", nil]),
        ScheduleRow(name: "Priya Raman",  cells: [nil, "8–4", "8–4", "8–4", nil, "9–5", "9–5"]),
        ScheduleRow(name: "Theo Brandt",  cells: ["5–1", "5–1", "5–1", "5–1", "5–1", nil, nil]),
        ScheduleRow(name: "Aisha Bello",  cells: [nil, "2–9", "2–9", nil, nil, "2–9", "2–9"]),
        ScheduleRow(name: "Jonah Klein",  cells: ["3–9", nil, "3–9", "3–9", "3–9", "4–10", nil])
    ]

    var unreadNotificationCount: Int { notifications.filter { !$0.isRead }.count }

    // MARK: - Init (used by SampleData / previews)
    init(currentUser: StaffMember, staff: [StaffMember], shift: [Shift],
         openShifts: [OpenShift], swaps: [Swap], timeOff: [TimeOff],
         threads: [MessageThread] = [], notifications: [AppNotification] = []) {
        self.currentUser    = currentUser
        self.staff          = staff
        self.shift          = shift
        self.openShifts     = openShifts
        self.swaps          = swaps
        self.timeOff        = timeOff
        self.threads        = threads
        self.notifications  = notifications
        self.isAuthenticated = true
    }

    // Production init — data loaded async after auth
    init() {
        currentUser   = .placeholder
        staff         = []
        shift         = []
        openShifts    = []
        swaps         = []
        timeOff       = []
        threads       = []
        notifications = []
    }

    // MARK: - Auth

    func signIn(email: String, password: String) async {
        isLoading = true
        authError = nil
        defer { isLoading = false }
        do {
            let session = try await supabase.auth.signIn(email: email, password: password)
            try await loadCurrentUser(userId: session.user.id)
            try await loadInitialData()
            isAuthenticated = true
        } catch {
            authError = error.localizedDescription
        }
    }

    func signOut() {
        Task {
            try? await supabase.auth.signOut()
            currentUser = .placeholder
            staff = []; shift = []; openShifts = []; swaps = []
            timeOff = []; threads = []; notifications = []
            isAuthenticated = false
        }
    }

    func restoreSession() async {
        do {
            let session = try await supabase.auth.session
            try await loadCurrentUser(userId: session.user.id)
            try await loadInitialData()
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }

    // MARK: - Load

    private func loadCurrentUser(userId: UUID) async throws {
        let employee: DBEmployee = try await supabase
            .from("employees")
            .select("id, name, role, permission_level, hourly_rate, hours_this_week, user_id")
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value
        currentUser = employee.toStaffMember
    }

    func loadInitialData() async throws {
        async let staffResult    = fetchStaff()
        async let shiftsResult   = fetchShifts()
        async let openResult     = fetchOpenShifts()
        async let swapsResult    = fetchSwaps()
        async let timeOffResult  = fetchTimeOff()
        async let notifsResult   = fetchNotifications()

        let (s, sh, os, sw, to, no) = try await
            (staffResult, shiftsResult, openResult, swapsResult, timeOffResult, notifsResult)

        staff = s; shift = sh; openShifts = os
        swaps = sw; timeOff = to; notifications = no
    }

    // MARK: - Fetches

    private func fetchStaff() async throws -> [StaffMember] {
        let rows: [DBEmployee] = try await supabase
            .from("employees")
            .select("id, name, role, permission_level, hourly_rate, hours_this_week, user_id")
            .eq("active", value: true)
            .execute()
            .value
        return rows.map(\.toStaffMember)
    }

    private func fetchShifts() async throws -> [Shift] {
        let rows: [DBShift] = try await supabase
            .from("kn_shifts")
            .select()
            .eq("employee_id", value: currentUser.id.uuidString)
            .execute()
            .value
        return rows.map(\.toShift)
    }

    private func fetchOpenShifts() async throws -> [OpenShift] {
        let rows: [DBOpenShift] = try await supabase
            .from("kn_open_shifts")
            .select()
            .execute()
            .value
        return rows.map { row in
            let name = staff.first(where: { $0.id == row.offeredById })?.name ?? "Staff"
            return row.toOpenShift(offeredByName: name)
        }
    }

    private func fetchSwaps() async throws -> [Swap] {
        let uid = currentUser.id.uuidString
        let rows: [DBSwap] = try await supabase
            .from("kn_swaps")
            .select()
            .or("from_employee_id.eq.\(uid),with_employee_id.eq.\(uid)")
            .execute()
            .value
        return rows.map { row in
            let fromName = staff.first(where: { $0.id == row.fromEmployeeId })?.name ?? "Staff"
            let withName = staff.first(where: { $0.id == row.withEmployeeId })?.name ?? "Staff"
            return row.toSwap(fromName: fromName, withName: withName, currentEmployeeId: currentUser.id)
        }
    }

    private func fetchTimeOff() async throws -> [TimeOff] {
        var query = supabase.from("kn_time_off").select()
        if !isManager {
            query = query.eq("employee_id", value: currentUser.id.uuidString)
        }
        let rows: [DBTimeOff] = try await query.execute().value
        return rows.map { row in
            let name = staff.first(where: { $0.id == row.employeeId })?.name ?? ""
            return row.toTimeOff(staffName: name)
        }
    }

    private func fetchNotifications() async throws -> [AppNotification] {
        let rows: [DBNotification] = try await supabase
            .from("kn_notifications")
            .select()
            .eq("employee_id", value: currentUser.id.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.map(\.toNotification)
    }
}
