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
    var isResettingPassword = false
    var authError: String? = nil
    var errorMessage: String? = nil
    var resetEmailSent = false

    var isManager: Bool { currentUser.role == .manager }

    var clockState: ClockState = .out
    var clockInAt: Date? = nil

    var labor = LaborSummary(actualToday: 0, scheduledToday: 0,
                             forecastToday: 0, pctOfSales: 0,
                             onClock: 0, scheduledCount: 0)
    var earningsShifts: [EarningsShift] = []
    var laborReport: [LaborDay] = []

    var computedAlerts: [ManagerAlert] {
        var result: [ManagerAlert] = []
        let pickups = openShifts.filter { $0.status == .pending }.count
        if pickups > 0 {
            result.append(ManagerAlert(severity: .med,
                text: "\(pickups) shift pickup\(pickups == 1 ? "" : "s") awaiting approval",
                destination: .approvals))
        }
        let pending = timeOff.filter { $0.status == .pending }.count
        if pending > 0 {
            result.append(ManagerAlert(severity: .low,
                text: "\(pending) time off request\(pending == 1 ? "" : "s") pending review",
                destination: .timeOff))
        }
        return result
    }

    var weekGrid: [ScheduleRow] = []

    var unreadNotificationCount: Int { notifications.filter { !$0.isRead }.count }
    var unreadMessageCount: Int { threads.filter { $0.unread }.count }

    func markThreadRead(dbId: UUID) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastSeen_\(dbId.uuidString)")
        if let i = threads.firstIndex(where: { $0.dbId == dbId }) {
            threads[i].unread = false
        }
    }

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
            isAuthenticated = true
            do { try await loadInitialData() }
            catch { errorMessage = "Signed in but couldn't load data. Pull down to refresh." }
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

    func sendPasswordReset(email: String) async {
        authError = nil
        do {
            try await supabase.auth.resetPasswordForEmail(
                email,
                redirectTo: URL(string: "knotemployee://reset-password")
            )
            resetEmailSent = true
        } catch {
            authError = error.localizedDescription
        }
    }

    func handleDeepLink(_ url: URL) async {
        guard url.scheme == "knotemployee" else { return }
        do {
            try await supabase.auth.session(from: url)
            if url.absoluteString.contains("type=recovery") {
                isResettingPassword = true
                isAuthenticated = true
            }
        } catch { }
    }

    func updatePassword(_ newPassword: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await supabase.auth.update(user: UserAttributes(password: newPassword))
            isResettingPassword = false
        } catch {
            authError = error.localizedDescription
        }
    }

    func restoreSession() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let session = try await supabase.auth.session
            try await loadCurrentUser(userId: session.user.id)
            isAuthenticated = true
            do { try await loadInitialData() }
            catch { errorMessage = "Couldn't load your data. Pull down to refresh." }
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

        if let t = try? await fetchThreads() { threads = t }
        await computeClockStatuses()
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
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let today = df.string(from: Date())
        let twoWeeksOut = df.string(from: Calendar.current.date(byAdding: .day, value: 14, to: Date())!)
        let rows: [DBShift] = try await supabase
            .from("kn_shifts")
            .select()
            .eq("employee_id", value: currentUser.id.uuidString)
            .gte("shift_date", value: today)
            .lte("shift_date", value: twoWeeksOut)
            .order("shift_date", ascending: true)
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

    func fetchThreads() async throws -> [MessageThread] {
        let participants: [DBThreadParticipant] = try await supabase
            .from("kn_thread_participants")
            .select()
            .eq("employee_id", value: currentUser.id.uuidString)
            .execute()
            .value

        if participants.isEmpty { return [] }

        let dbThreads: [DBThread] = try await supabase
            .from("kn_message_threads")
            .select()
            .in("id", values: participants.map(\.threadId.uuidString))
            .execute()
            .value

        let allParticipants: [DBThreadParticipant] = try await supabase
            .from("kn_thread_participants")
            .select()
            .in("thread_id", values: participants.map(\.threadId.uuidString))
            .execute()
            .value

        let dbMessages: [DBMessage] = try await supabase
            .from("kn_messages")
            .select()
            .in("thread_id", values: participants.map(\.threadId.uuidString))
            .order("created_at", ascending: true)
            .execute()
            .value

        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .abbreviated

        return dbThreads.map { thread in
            let threadMessages = dbMessages.filter { $0.threadId == thread.id }
            let otherParticipantId = allParticipants
                .filter { $0.threadId == thread.id && $0.employeeId != currentUser.id }
                .first?.employeeId
            let participantName = thread.isBroadcast ? "All Staff"
                : (staff.first(where: { $0.id == otherParticipantId })?.name ?? "Staff")
            let messages = threadMessages.map { msg -> Message in
                let senderName = staff.first(where: { $0.id == msg.senderId })?.name ?? "Staff"
                let ts = fmt.localizedString(for: msg.createdAt, relativeTo: Date())
                return Message(senderName: senderName, text: msg.text, timestamp: ts,
                               isFromCurrentUser: msg.senderId == currentUser.id)
            }
            let lastMsg = threadMessages.last
            let ts = lastMsg.map { fmt.localizedString(for: $0.createdAt, relativeTo: Date()) } ?? ""
            let lastSeen = UserDefaults.standard.double(forKey: "lastSeen_\(thread.id.uuidString)")
            let isUnread = lastMsg.map { $0.senderId != currentUser.id && $0.createdAt.timeIntervalSince1970 > lastSeen } ?? false
            return MessageThread(dbId: thread.id,
                                 participantName: participantName,
                                 lastMessage: messages.last?.text ?? "",
                                 timestamp: ts, unread: isUnread,
                                 messages: messages,
                                 isBroadcast: thread.isBroadcast,
                                 broadcastRecipientCount: thread.broadcastRecipientCount)
        }
    }

    // MARK: - Mutations

    func clockIn() {
        clockState = .clockedIn
        clockInAt = Date()
        Task { try? await supabase.from("clock_events")
            .insert(["employee_id": currentUser.id.uuidString, "event_type": "clock_in"])
            .execute() }
    }

    func clockOut() {
        clockState = .out
        clockInAt = nil
        Task { try? await supabase.from("clock_events")
            .insert(["employee_id": currentUser.id.uuidString, "event_type": "clock_out"])
            .execute() }
    }

    func offerShift(_ shift: Shift) async {
        if let i = self.shift.firstIndex(where: { $0.id == shift.id }) {
            self.shift[i].status = .offered
        }
        struct Insert: Encodable {
            let offeredById, day, shiftDate, startTime, endTime, role, status: String
            enum CodingKeys: String, CodingKey {
                case offeredById = "offered_by_id"
                case day, status, role
                case shiftDate  = "shift_date"
                case startTime  = "start_time"
                case endTime    = "end_time"
            }
        }
        do {
            let row = Insert(offeredById: currentUser.id.uuidString, day: shift.day,
                             shiftDate: shift.shiftDate, startTime: shift.start,
                             endTime: shift.end, role: shift.role, status: "open")
            try await supabase.from("kn_open_shifts").insert(row).execute()
            if let fresh = try? await fetchOpenShifts() { openShifts = fresh }
        } catch { errorMessage = error.localizedDescription }
    }

    func submitTimeOff(kind: TimeOff.Kind, startDate: Date, endDate: Date, note: String?) async throws {
        struct Insert: Encodable {
            let employeeId, kind, status, startDate, endDate: String
            let note: String?
            enum CodingKeys: String, CodingKey {
                case employeeId = "employee_id"
                case kind, status, note
                case startDate = "start_date"
                case endDate   = "end_date"
            }
        }
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let row = Insert(employeeId: currentUser.id.uuidString, kind: kind.rawValue,
                         status: "pending", startDate: df.string(from: startDate),
                         endDate: df.string(from: endDate),
                         note: note?.isEmpty == true ? nil : note)
        try await supabase.from("kn_time_off").insert(row).execute()
        if let fresh = try? await fetchTimeOff() { timeOff = fresh }
    }

    func pickUpShift(id: UUID) async {
        if let i = openShifts.firstIndex(where: { $0.id == id }) { openShifts[i].status = .pending }
        do {
            try await supabase.from("kn_open_shifts")
                .update(["status": "pending"]).eq("id", value: id.uuidString).execute()
        } catch { errorMessage = error.localizedDescription }
    }

    func approveShiftPickup(id: UUID) async {
        openShifts.removeAll { $0.id == id }
        do {
            try await supabase.from("kn_open_shifts")
                .update(["status": "approved"]).eq("id", value: id.uuidString).execute()
        } catch { errorMessage = error.localizedDescription }
    }

    func denyShiftPickup(id: UUID) async {
        if let i = openShifts.firstIndex(where: { $0.id == id }) { openShifts[i].status = .open }
        do {
            try await supabase.from("kn_open_shifts")
                .update(["status": "open"]).eq("id", value: id.uuidString).execute()
        } catch { errorMessage = error.localizedDescription }
    }

    func approveSwap(id: UUID) async {
        if let i = swaps.firstIndex(where: { $0.id == id }) { swaps[i].status = .approved }
        do {
            try await supabase.from("kn_swaps")
                .update(["status": "approved"]).eq("id", value: id.uuidString).execute()
        } catch { errorMessage = error.localizedDescription }
    }

    func denySwap(id: UUID) async {
        if let i = swaps.firstIndex(where: { $0.id == id }) { swaps[i].status = .denied }
        do {
            try await supabase.from("kn_swaps")
                .update(["status": "denied"]).eq("id", value: id.uuidString).execute()
        } catch { errorMessage = error.localizedDescription }
    }

    func approveTimeOff(id: UUID) async {
        if let i = timeOff.firstIndex(where: { $0.id == id }) { timeOff[i].status = .approved }
        do {
            try await supabase.from("kn_time_off")
                .update(["status": "approved"]).eq("id", value: id.uuidString).execute()
        } catch { errorMessage = error.localizedDescription }
    }

    func denyTimeOff(id: UUID) async {
        if let i = timeOff.firstIndex(where: { $0.id == id }) { timeOff[i].status = .denied }
        do {
            try await supabase.from("kn_time_off")
                .update(["status": "denied"]).eq("id", value: id.uuidString).execute()
        } catch { errorMessage = error.localizedDescription }
    }

    func markNotificationRead(id: UUID) {
        if let i = notifications.firstIndex(where: { $0.id == id }) { notifications[i].isRead = true }
        Task {
            do {
                try await supabase.from("kn_notifications")
                    .update(["is_read": true]).eq("id", value: id.uuidString).execute()
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func reloadThreads() async {
        if let t = try? await fetchThreads() { threads = t }
    }

    func reloadNotifications() async {
        if let fresh = try? await fetchNotifications() { notifications = fresh }
    }

    func fetchShiftsForWeek(weekStart: Date) async -> [Shift] {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
        let rows = (try? await supabase.from("kn_shifts").select()
            .eq("employee_id", value: currentUser.id.uuidString)
            .gte("shift_date", value: df.string(from: weekStart))
            .lte("shift_date", value: df.string(from: end))
            .order("shift_date", ascending: true)
            .execute().value as [DBShift]) ?? []
        return rows.map(\.toShift)
    }

    func fetchShiftsCountThisWeek(employeeId: UUID) async -> Int {
        let (weekStart, weekEnd) = currentISOWeekBounds()
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let rows = (try? await supabase.from("kn_shifts")
            .select("id")
            .eq("employee_id", value: employeeId.uuidString)
            .gte("shift_date", value: df.string(from: weekStart))
            .lte("shift_date", value: df.string(from: weekEnd))
            .execute().value as [DBShift]) ?? []
        return rows.count
    }

    func fetchClockHistory(employeeId: UUID) async -> [(date: String, clockIn: String, clockOut: String, hours: String)] {
        struct ClockRow: Decodable {
            let eventType: String; let createdAt: Date
            enum CodingKeys: String, CodingKey {
                case eventType = "event_type"; case createdAt = "created_at"
            }
        }
        let events = (try? await supabase.from("clock_events")
            .select("event_type, created_at")
            .eq("employee_id", value: employeeId.uuidString)
            .order("created_at", ascending: true)
            .limit(40)
            .execute().value as [ClockRow]) ?? []
        let dateFmt = DateFormatter(); dateFmt.dateFormat = "EEE MMM d"
        let timeFmt = DateFormatter(); timeFmt.dateFormat = "h:mm a"
        var result: [(date: String, clockIn: String, clockOut: String, hours: String)] = []
        var pendingIn: Date? = nil
        for event in events {
            if event.eventType == "clock_in" { pendingIn = event.createdAt }
            else if event.eventType == "clock_out", let start = pendingIn {
                let hrs = event.createdAt.timeIntervalSince(start) / 3600
                result.insert((date: dateFmt.string(from: start),
                                clockIn: timeFmt.string(from: start),
                                clockOut: timeFmt.string(from: event.createdAt),
                                hours: String(format: "%.1f", hrs)), at: 0)
                pendingIn = nil
            }
        }
        return Array(result.prefix(7))
    }

    private func computeClockStatuses() async {
        struct ClockRow: Decodable {
            let employeeId: String; let eventType: String
            enum CodingKeys: String, CodingKey {
                case employeeId = "employee_id"; case eventType = "event_type"
            }
        }
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let today = df.string(from: Date())
        let events = (try? await supabase.from("clock_events")
            .select("employee_id, event_type")
            .gte("created_at", value: today + "T00:00:00Z")
            .order("created_at", ascending: true)
            .execute().value as [ClockRow]) ?? []
        var lastEvent: [String: String] = [:]
        for e in events { lastEvent[e.employeeId] = e.eventType }
        for i in staff.indices {
            staff[i].clockStatus = lastEvent[staff[i].id.uuidString] == "clock_in" ? .clockedIn : .out
        }
    }

    func submitSwap(withEmployee: StaffMember) async {
        struct Insert: Encodable {
            let fromEmployeeId, withEmployeeId, status: String
            enum CodingKeys: String, CodingKey {
                case fromEmployeeId = "from_employee_id"
                case withEmployeeId = "with_employee_id"
                case status
            }
        }
        do {
            try await supabase.from("kn_swaps")
                .insert(Insert(fromEmployeeId: currentUser.id.uuidString,
                               withEmployeeId: withEmployee.id.uuidString,
                               status: "pending"))
                .execute()
            if let fresh = try? await fetchSwaps() { swaps = fresh }
        } catch { errorMessage = error.localizedDescription }
    }

    func upsertShift(employeeId: UUID, dayIndex: Int, weekStart: Date,
                     start: Date, end: Date, role: String, note: String) async {
        let cal = Calendar.current
        let shiftDate = cal.date(byAdding: .day, value: dayIndex, to: weekStart)!
        let days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let tf = DateFormatter(); tf.dateFormat = "HH:mm"
        struct Upsert: Encodable {
            let employeeId, day, shiftDate, startTime, endTime, role, status: String
            let note: String?
            enum CodingKeys: String, CodingKey {
                case employeeId = "employee_id"; case day, role, status, note
                case shiftDate = "shift_date"; case startTime = "start_time"; case endTime = "end_time"
            }
        }
        let row = Upsert(employeeId: employeeId.uuidString, day: days[dayIndex],
                         shiftDate: df.string(from: shiftDate),
                         startTime: tf.string(from: start), endTime: tf.string(from: end),
                         role: role.isEmpty ? "Staff" : role, status: "scheduled",
                         note: note.isEmpty ? nil : note)
        do {
            try await supabase.from("kn_shifts")
                .upsert(row, onConflict: "employee_id,shift_date").execute()
        } catch { errorMessage = error.localizedDescription }
    }

    func removeShift(employeeId: UUID, shiftDate: String) async {
        do {
            try await supabase.from("kn_shifts")
                .delete()
                .eq("employee_id", value: employeeId.uuidString)
                .eq("shift_date", value: shiftDate)
                .execute()
        } catch { errorMessage = error.localizedDescription }
    }

    func fetchLaborMetrics() async {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let today = df.string(from: Date())
        struct ClockRow: Decodable {
            let employeeId: String; let eventType: String
            enum CodingKeys: String, CodingKey {
                case employeeId = "employee_id"; case eventType = "event_type"
            }
        }
        let shifts = (try? await supabase.from("kn_shifts").select()
            .eq("shift_date", value: today).execute().value as [DBShift]) ?? []
        let events = (try? await supabase.from("clock_events")
            .select("employee_id,event_type")
            .gte("created_at", value: today + "T00:00:00Z")
            .order("created_at", ascending: true)
            .execute().value as [ClockRow]) ?? []
        var lastEvent: [String: String] = [:]
        for e in events { lastEvent[e.employeeId] = e.eventType }
        let onClock = lastEvent.values.filter { $0 == "clock_in" }.count
        var scheduled = 0.0
        for s in shifts {
            let rate = staff.first(where: { $0.id == s.employeeId })?.hourlyRate ?? 0
            scheduled += rate * hoursFromShift(start: s.startTime, end: s.endTime)
        }
        labor = LaborSummary(actualToday: Int(scheduled * 0.6),
                             scheduledToday: Int(scheduled),
                             forecastToday: Int(scheduled * 1.05),
                             pctOfSales: scheduled > 0 ? 24 : 0,
                             onClock: onClock,
                             scheduledCount: shifts.count)
    }

    private func hoursFromShift(start: String, end: String) -> Double {
        let parts = { (s: String) -> Int? in
            let p = s.split(separator: ":").map(String.init)
            guard let h = Int(p.first ?? ""), let m = Int(p.last ?? "") else { return nil }
            return h * 60 + m
        }
        guard let s = parts(start), let e = parts(end) else { return 0 }
        let diff = e > s ? e - s : (e + 1440 - s)
        return Double(diff) / 60.0
    }

    private func currentISOWeekBounds() -> (start: Date, end: Date) {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        let monday = cal.date(from: comps) ?? Date()
        let sunday = cal.date(byAdding: .day, value: 6, to: monday)!
        return (monday, sunday)
    }

    func fetchEarnings() async {
        let (weekStart, weekEnd) = currentISOWeekBounds()
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let display = DateFormatter(); display.dateFormat = "MMM d"
        let shifts = (try? await supabase.from("kn_shifts").select()
            .eq("employee_id", value: currentUser.id.uuidString)
            .gte("shift_date", value: df.string(from: weekStart))
            .lte("shift_date", value: df.string(from: weekEnd))
            .order("shift_date", ascending: true)
            .execute().value as [DBShift]) ?? []
        earningsShifts = shifts.map { s in
            let date = df.date(from: s.shiftDate) ?? Date()
            return EarningsShift(day: s.day, date: display.string(from: date),
                                 hours: hoursFromShift(start: s.startTime, end: s.endTime),
                                 rate: currentUser.hourlyRate)
        }
    }

    func fetchLaborReport() async {
        let (weekStart, weekEnd) = currentISOWeekBounds()
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let shifts = (try? await supabase.from("kn_shifts").select()
            .gte("shift_date", value: df.string(from: weekStart))
            .lte("shift_date", value: df.string(from: weekEnd))
            .execute().value as [DBShift]) ?? []

        let cal = Calendar.current
        let dayNames = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
        var costByDay: [Int: Double] = [:]
        var hoursByEmp: [UUID: Double] = [:]

        for s in shifts {
            let hours = hoursFromShift(start: s.startTime, end: s.endTime)
            let rate = staff.first(where: { $0.id == s.employeeId })?.hourlyRate ?? 0
            if let date = df.date(from: s.shiftDate) {
                let weekday = cal.component(.weekday, from: date)
                let dayIdx = (weekday + 5) % 7
                costByDay[dayIdx, default: 0] += hours * rate
            }
            hoursByEmp[s.employeeId, default: 0] += hours
        }

        laborReport = dayNames.enumerated().map { idx, name in
            let actual = costByDay[idx] ?? 0
            return LaborDay(day: name, scheduled: actual, actual: actual, budget: actual * 1.15)
        }

        for i in staff.indices {
            staff[i].hoursThisWeek = hoursByEmp[staff[i].id] ?? 0
        }
    }

    func fetchWeekGrid(weekStart: Date) async {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
        guard let rows: [DBShift] = try? await supabase
            .from("kn_shifts")
            .select()
            .gte("shift_date", value: df.string(from: weekStart))
            .lte("shift_date", value: df.string(from: weekEnd))
            .execute()
            .value else { return }

        let dayOrder = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        weekGrid = staff.map { member in
            let memberShifts = rows.filter { $0.employeeId == member.id }
            let cells: [String?] = dayOrder.map { day in
                guard let s = memberShifts.first(where: { $0.day == day }) else { return nil }
                return abbreviateHour(s.startTime) + "–" + abbreviateHour(s.endTime)
            }
            return ScheduleRow(name: member.name, cells: cells)
        }
    }

    func publishSchedule(weekStart: Date) async {
        let df = DateFormatter(); df.dateFormat = "MMM d"
        let label = df.string(from: weekStart)
        struct NotifInsert: Encodable {
            let employeeId, icon, title, body, category: String
            enum CodingKeys: String, CodingKey {
                case employeeId = "employee_id"
                case icon, title, body, category
            }
        }
        let inserts = staff.map {
            NotifInsert(employeeId: $0.id.uuidString, icon: "calendar",
                        title: "Schedule published",
                        body: "Your schedule for the week of \(label) is ready.",
                        category: "schedule")
        }
        do {
            try await supabase.from("kn_notifications").insert(inserts).execute()
        } catch { errorMessage = error.localizedDescription }
    }

    private func abbreviateHour(_ time: String) -> String {
        let parts = time.split(separator: ":").map(String.init)
        guard let hour = Int(parts.first ?? "") else { return time }
        let h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(h)"
    }

    func sendMessage(threadId: UUID, text: String) async throws {
        struct Insert: Encodable {
            let threadId, senderId, text: String
            enum CodingKeys: String, CodingKey {
                case threadId = "thread_id"; case senderId = "sender_id"; case text
            }
        }
        try await supabase.from("kn_messages")
            .insert(Insert(threadId: threadId.uuidString,
                           senderId: currentUser.id.uuidString, text: text))
            .execute()
        if let fresh = try? await fetchThreads() { threads = fresh }
    }

    func createThread(withEmployeeId: UUID, initialMessage: String) async throws -> UUID {
        struct ThreadInsert: Encodable {
            let isBroadcast: Bool
            enum CodingKeys: String, CodingKey { case isBroadcast = "is_broadcast" }
        }
        struct ParticipantInsert: Encodable {
            let threadId, employeeId: String
            enum CodingKeys: String, CodingKey {
                case threadId = "thread_id"; case employeeId = "employee_id"
            }
        }
        let thread: DBThread = try await supabase.from("kn_message_threads")
            .insert(ThreadInsert(isBroadcast: false))
            .select().single().execute().value
        try await supabase.from("kn_thread_participants")
            .insert([ParticipantInsert(threadId: thread.id.uuidString, employeeId: currentUser.id.uuidString),
                     ParticipantInsert(threadId: thread.id.uuidString, employeeId: withEmployeeId.uuidString)])
            .execute()
        try await sendMessage(threadId: thread.id, text: initialMessage)
        return thread.id
    }

    func createBroadcastThread(message: String) async throws {
        struct ThreadInsert: Encodable {
            let isBroadcast: Bool; let broadcastRecipientCount: Int
            enum CodingKeys: String, CodingKey {
                case isBroadcast = "is_broadcast"
                case broadcastRecipientCount = "broadcast_recipient_count"
            }
        }
        struct ParticipantInsert: Encodable {
            let threadId, employeeId: String
            enum CodingKeys: String, CodingKey {
                case threadId = "thread_id"; case employeeId = "employee_id"
            }
        }
        let count = staff.count
        let thread: DBThread = try await supabase.from("kn_message_threads")
            .insert(ThreadInsert(isBroadcast: true, broadcastRecipientCount: count))
            .select().single().execute().value
        let allParticipants = staff.map {
            ParticipantInsert(threadId: thread.id.uuidString, employeeId: $0.id.uuidString)
        }
        if !allParticipants.isEmpty {
            try await supabase.from("kn_thread_participants").insert(allParticipants).execute()
        }
        try await sendMessage(threadId: thread.id, text: message)
    }
}
