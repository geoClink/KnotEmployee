import Observation
import Foundation
import Supabase
import UserNotifications
import Network

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
    var employeeId: UUID? = nil
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

struct ScheduleTemplate: Identifiable {
    let id: UUID
    var name: String
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
    var availability: [Bool] = [Bool](repeating: true, count: 7)
    var templates: [ScheduleTemplate] = []
    var allStaffAvailability: [UUID: [Bool]] = [:]
    var actualHoursByEmployee: [UUID: Double] = [:]
    private var realtimeTask: Task<Void, Never>?
    private let networkMonitor = NWPathMonitor()
    var isOffline = false
    var selectedTab = 0
    var weeklyLaborBudget: Double = 0

    var computedAlerts: [ManagerAlert] {
        var result: [ManagerAlert] = []
        let overtime = staff.filter { $0.hoursThisWeek >= 40 }
        if !overtime.isEmpty {
            result.append(ManagerAlert(severity: .high,
                text: "\(overtime.count) employee\(overtime.count == 1 ? "" : "s") at or over 40 hrs",
                destination: .labor))
        }
        let approaching = staff.filter { $0.hoursThisWeek >= 35 && $0.hoursThisWeek < 40 }
        if !approaching.isEmpty {
            result.append(ManagerAlert(severity: .med,
                text: "\(approaching.count) employee\(approaching.count == 1 ? "" : "s") approaching overtime",
                destination: .labor))
        }
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
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isOffline = path.status != .satisfied
            }
        }
        networkMonitor.start(queue: DispatchQueue(label: "kn.network"))
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
        unsubscribeFromRealtime()
        Task {
            try? await supabase.auth.signOut()
            currentUser = .placeholder
            staff = []; shift = []; openShifts = []; swaps = []
            timeOff = []; threads = []; notifications = []
            selectedTab = 0
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

    // Creates the auth account + employees row, then signs out so manager can re-login
    func addEmployee(name: String, jobTitle: String, email: String,
                     password: String, hourlyRate: Double, isManager: Bool) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            // Snapshot the manager's session before signUp replaces it.
            let managerSession = try await supabase.auth.session

            let authResponse = try await supabase.auth.signUp(email: email, password: password)
            let newUserId = authResponse.user.id

            // Restore the manager's session so the employees insert passes RLS.
            try await supabase.auth.setSession(
                accessToken: managerSession.accessToken,
                refreshToken: managerSession.refreshToken
            )

            struct NewEmployee: Encodable {
                let name, role, tenantId: String
                let permissionLevel: Int
                let hourlyRate: Double
                let active: Bool
                let userId: UUID
                enum CodingKeys: String, CodingKey {
                    case name, role, active
                    case tenantId = "tenant_id"
                    case permissionLevel = "permission_level"
                    case hourlyRate = "hourly_rate"
                    case userId = "user_id"
                }
            }
            try await supabase.from("employees")
                .insert(NewEmployee(name: name, role: jobTitle, tenantId: Config.tenantId,
                                    permissionLevel: isManager ? 2 : 1,
                                    hourlyRate: hourlyRate, active: true, userId: newUserId))
                .execute()
            try? await supabase.auth.signOut()
            isAuthenticated = false
            currentUser = .placeholder
            staff = []; shift = []; openShifts = []; swaps = []
            timeOff = []; threads = []; notifications = []
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func scheduleShiftReminders() {
        let center = UNUserNotificationCenter.current()
        let enabled = UserDefaults.standard.object(forKey: "notifShifts") as? Bool ?? true
        let existingIds = shift.map { "shift-reminder-\($0.id)" }
        center.removePendingNotificationRequests(withIdentifiers: existingIds)
        guard enabled else { return }

        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        for s in shift {
            guard let shiftDay = df.date(from: s.shiftDate) else { continue }
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: shiftDay)
            comps.hour = 8; comps.minute = 0
            guard let fireAt = Calendar.current.date(from: comps),
                  fireAt > Date() else { continue }
            let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: fireAt) ?? fireAt
            guard reminderDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Shift tomorrow"
            content.body = "\(s.role) · \(s.timeRange)"
            content.sound = .default

            let triggerComps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: false)
            let request = UNNotificationRequest(identifier: "shift-reminder-\(s.id)", content: content, trigger: trigger)
            center.add(request)
        }
    }

    func registerDeviceToken(_ token: String) {
        Task {
            try? await supabase.from("device_tokens")
                .upsert(["employee_id": currentUser.id.uuidString,
                         "token": token, "platform": "apns",
                         "tenant_id": Config.tenantId],
                        onConflict: "employee_id")
                .execute()
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
            .select("id, name, role, permission_level, hourly_rate, hours_this_week, user_id, pto_days_remaining")
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
        await restoreClockState()
        await fetchAvailability()
        await fetchAllStaffAvailability()
        subscribeToRealtime()
        scheduleShiftReminders()
        if isManager { await fetchLaborReport(); await fetchLaborMetrics(); await fetchLaborBudget() }
    }

    private func restoreClockState() async {
        struct ClockRow: Decodable {
            let eventType: String; let createdAt: Date
            enum CodingKeys: String, CodingKey {
                case eventType = "event_type"; case createdAt = "created_at"
            }
        }
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let today = df.string(from: Date())
        let events = (try? await supabase.from("clock_events")
            .select("event_type, created_at")
            .eq("employee_id", value: currentUser.id.uuidString)
            .gte("created_at", value: today + "T00:00:00Z")
            .order("created_at", ascending: true)
            .execute().value as [ClockRow]) ?? []
        guard let last = events.last else { return }
        switch last.eventType {
        case "clock_in":
            clockState = .clockedIn
            clockInAt = last.createdAt
        case "break_start":
            clockState = .onBreak
            clockInAt = events.last(where: { $0.eventType == "clock_in" })?.createdAt
        default:
            clockState = .out
            clockInAt = nil
        }
    }

    // MARK: - Fetches

    private func fetchStaff() async throws -> [StaffMember] {
        let rows: [DBEmployee] = try await supabase
            .from("employees")
            .select("id, name, role, permission_level, hourly_rate, hours_this_week, user_id, pto_days_remaining")
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
            let name = row.offeredById == currentUser.id
                ? "You"
                : (staff.first(where: { $0.id == row.offeredById })?.name ?? "Staff")
            return row.toOpenShift(offeredByName: name)
        }
    }

    private func fetchSwaps() async throws -> [Swap] {
        let uid = currentUser.id.uuidString
        var query = supabase.from("kn_swaps").select()
        if !isManager {
            query = query.or("from_employee_id.eq.\(uid),with_employee_id.eq.\(uid)")
        }
        let rows: [DBSwap] = try await query.execute().value
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
            .insert(["employee_id": currentUser.id.uuidString, "event_type": "clock_in",
                     "tenant_id": Config.tenantId])
            .execute() }
    }

    func clockOut() {
        clockState = .out
        clockInAt = nil
        Task { try? await supabase.from("clock_events")
            .insert(["employee_id": currentUser.id.uuidString, "event_type": "clock_out",
                     "tenant_id": Config.tenantId])
            .execute() }
    }

    func confirmShift(id: UUID) async {
        if let i = shift.firstIndex(where: { $0.id == id }) { shift[i].confirmed = true }
        try? await supabase.from("kn_shifts")
            .update(["confirmed": true]).eq("id", value: id.uuidString).execute()
    }

    func fetchAvailability() async {
        struct DBAvailability: Decodable {
            let dayOfWeek: Int; let available: Bool
            enum CodingKeys: String, CodingKey {
                case dayOfWeek = "day_of_week"; case available
            }
        }
        let rows = (try? await supabase.from("kn_availability")
            .select("day_of_week, available")
            .eq("employee_id", value: currentUser.id.uuidString)
            .execute().value as [DBAvailability]) ?? []
        var avail = [Bool](repeating: true, count: 7)
        for row in rows { if row.dayOfWeek < 7 { avail[row.dayOfWeek] = row.available } }
        availability = avail
    }

    func fetchAllStaffAvailability() async {
        struct DBAvailability: Decodable {
            let employeeId: UUID; let dayOfWeek: Int; let available: Bool
            enum CodingKeys: String, CodingKey {
                case employeeId = "employee_id"; case dayOfWeek = "day_of_week"; case available
            }
        }
        let rows = (try? await supabase.from("kn_availability")
            .select("employee_id, day_of_week, available")
            .execute().value as [DBAvailability]) ?? []
        var result: [UUID: [Bool]] = [:]
        for row in rows {
            if result[row.employeeId] == nil { result[row.employeeId] = [Bool](repeating: true, count: 7) }
            if row.dayOfWeek < 7 { result[row.employeeId]![row.dayOfWeek] = row.available }
        }
        allStaffAvailability = result
    }

    func saveAvailability(_ avail: [Bool]) async {
        availability = avail
        struct Row: Encodable {
            let employeeId, tenantId: String; let dayOfWeek: Int; let available: Bool
            enum CodingKeys: String, CodingKey {
                case employeeId = "employee_id"; case tenantId = "tenant_id"
                case dayOfWeek = "day_of_week"; case available
            }
        }
        let rows = avail.enumerated().map { Row(employeeId: currentUser.id.uuidString,
                                                tenantId: Config.tenantId,
                                                dayOfWeek: $0.offset, available: $0.element) }
        try? await supabase.from("kn_availability")
            .upsert(rows, onConflict: "employee_id,day_of_week").execute()
    }

    // MARK: - Schedule Templates

    func fetchTemplates() async {
        struct DBTemplate: Decodable { let id: UUID; let name: String }
        templates = (try? await supabase.from("kn_schedule_templates")
            .select("id, name").order("created_at", ascending: false)
            .execute().value as [DBTemplate])?
            .map { ScheduleTemplate(id: $0.id, name: $0.name) } ?? []
    }

    func deleteTemplate(id: UUID) async {
        try? await supabase.from("kn_schedule_templates").delete().eq("id", value: id.uuidString).execute()
        templates.removeAll { $0.id == id }
    }

    func saveAsTemplate(name: String, weekStart: Date) async {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
        struct DBShiftRow: Decodable {
            let employeeId: UUID; let day, startTime, endTime, role: String
            enum CodingKeys: String, CodingKey {
                case employeeId = "employee_id"; case day
                case startTime = "start_time"; case endTime = "end_time"; case role
            }
        }
        guard let shifts: [DBShiftRow] = try? await supabase.from("kn_shifts")
            .select("employee_id, day, start_time, end_time, role")
            .gte("shift_date", value: df.string(from: weekStart))
            .lte("shift_date", value: df.string(from: weekEnd))
            .execute().value else { return }
        struct NewTemplate: Encodable {
            let name, tenantId: String
            enum CodingKeys: String, CodingKey { case name; case tenantId = "tenant_id" }
        }
        struct CreatedTemplate: Decodable { let id: UUID }
        guard let created: CreatedTemplate = try? await supabase.from("kn_schedule_templates")
            .insert(NewTemplate(name: name, tenantId: Config.tenantId)).select("id").single().execute().value else { return }
        struct TemplateShift: Encodable {
            let templateId: UUID; let employeeId: UUID; let dayOfWeek: Int
            let startTime, endTime, role, tenantId: String
            enum CodingKeys: String, CodingKey {
                case templateId = "template_id"; case employeeId = "employee_id"
                case dayOfWeek = "day_of_week"; case startTime = "start_time"
                case endTime = "end_time"; case role; case tenantId = "tenant_id"
            }
        }
        let dayMap = ["Mon": 0, "Tue": 1, "Wed": 2, "Thu": 3, "Fri": 4, "Sat": 5, "Sun": 6]
        let rows = shifts.compactMap { s -> TemplateShift? in
            guard let dow = dayMap[s.day] else { return nil }
            return TemplateShift(templateId: created.id, employeeId: s.employeeId,
                                 dayOfWeek: dow, startTime: s.startTime, endTime: s.endTime,
                                 role: s.role, tenantId: Config.tenantId)
        }
        try? await supabase.from("kn_template_shifts").insert(rows).execute()
        await fetchTemplates()
    }

    func applyTemplate(id: UUID, weekStart: Date) async {
        struct DBTemplateShift: Decodable {
            let employeeId: UUID; let dayOfWeek: Int; let startTime, endTime, role: String
            enum CodingKeys: String, CodingKey {
                case employeeId = "employee_id"; case dayOfWeek = "day_of_week"
                case startTime = "start_time"; case endTime = "end_time"; case role
            }
        }
        guard let rows: [DBTemplateShift] = try? await supabase.from("kn_template_shifts")
            .select("employee_id, day_of_week, start_time, end_time, role")
            .eq("template_id", value: id.uuidString).execute().value else { return }
        let cal = Calendar.current; let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let dayNames = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        struct ShiftUpsert: Encodable {
            let employeeId: UUID; let day, shiftDate, startTime, endTime, role, tenantId: String
            enum CodingKeys: String, CodingKey {
                case employeeId = "employee_id"; case day
                case shiftDate = "shift_date"; case startTime = "start_time"
                case endTime = "end_time"; case role; case tenantId = "tenant_id"
            }
        }
        let upserts = rows.map { ts -> ShiftUpsert in
            let date = cal.date(byAdding: .day, value: ts.dayOfWeek, to: weekStart)!
            return ShiftUpsert(employeeId: ts.employeeId, day: dayNames[ts.dayOfWeek],
                               shiftDate: df.string(from: date),
                               startTime: ts.startTime, endTime: ts.endTime, role: ts.role,
                               tenantId: Config.tenantId)
        }
        try? await supabase.from("kn_shifts")
            .upsert(upserts, onConflict: "employee_id,shift_date").execute()
        await fetchWeekGrid(weekStart: weekStart)
    }

    // MARK: - Realtime

    func subscribeToRealtime() {
        realtimeTask?.cancel()
        realtimeTask = Task {
            while !Task.isCancelled {
                let channel = supabase.channel("realtime-\(currentUser.id.uuidString)")

                let messageInserts  = channel.postgresChange(InsertAction.self, schema: "public", table: "kn_messages")
                let notifInserts    = channel.postgresChange(InsertAction.self, schema: "public", table: "kn_notifications")
                let swapChanges     = channel.postgresChange(AnyAction.self,    schema: "public", table: "kn_swaps")
                let timeOffChanges  = channel.postgresChange(AnyAction.self,    schema: "public", table: "kn_time_off")
                let shiftChanges    = channel.postgresChange(AnyAction.self,    schema: "public", table: "kn_shifts")

                await channel.subscribe()

                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        for await insert in messageInserts { await self.handleIncomingMessage(insert) }
                    }
                    group.addTask {
                        for await _ in notifInserts { await self.reloadNotifications() }
                    }
                    group.addTask {
                        for await _ in swapChanges { await self.reloadSwaps() }
                    }
                    group.addTask {
                        for await _ in timeOffChanges { await self.reloadTimeOff() }
                    }
                    group.addTask {
                        for await _ in shiftChanges { await self.reloadShifts() }
                    }
                }

                if !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                }
            }
        }
    }

    func unsubscribeFromRealtime() {
        realtimeTask?.cancel()
        realtimeTask = nil
    }

    private func handleIncomingMessage(_ insert: InsertAction) async {
        let r = insert.record
        guard let threadIdStr = r["thread_id"]?.stringValue,
              let threadId = UUID(uuidString: threadIdStr) else { return }
        guard let i = threads.firstIndex(where: { $0.dbId == threadId }) else {
            await reloadThreads()
            return
        }
        let senderIdStr = r["sender_id"]?.stringValue ?? ""
        let isMe = senderIdStr == currentUser.id.uuidString
        let text = r["text"]?.stringValue ?? ""
        let senderName = isMe ? currentUser.name
            : (staff.first(where: { $0.id.uuidString == senderIdStr })?.name ?? "Staff")
        let msg = Message(senderName: senderName, text: text,
                          timestamp: "Just now", isFromCurrentUser: isMe)
        threads[i].messages.append(msg)
        threads[i].lastMessage = text
        threads[i].timestamp = "Just now"
        if !isMe { threads[i].unread = true }
    }

    func startBreak() {
        clockState = .onBreak
        Task { try? await supabase.from("clock_events")
            .insert(["employee_id": currentUser.id.uuidString, "event_type": "break_start",
                     "tenant_id": Config.tenantId])
            .execute() }
    }

    func endBreak() {
        clockState = .clockedIn
        Task { try? await supabase.from("clock_events")
            .insert(["employee_id": currentUser.id.uuidString, "event_type": "break_end",
                     "tenant_id": Config.tenantId])
            .execute() }
    }

    func offerShift(_ shift: Shift) async {
        if let i = self.shift.firstIndex(where: { $0.id == shift.id }) {
            self.shift[i].status = .offered
        }
        struct Insert: Encodable {
            let offeredById, day, shiftDate, startTime, endTime, role, status, tenantId: String
            enum CodingKeys: String, CodingKey {
                case offeredById = "offered_by_id"
                case day, status, role
                case shiftDate  = "shift_date"
                case startTime  = "start_time"
                case endTime    = "end_time"
                case tenantId   = "tenant_id"
            }
        }
        do {
            let row = Insert(offeredById: currentUser.id.uuidString, day: shift.day,
                             shiftDate: shift.shiftDate, startTime: shift.start,
                             endTime: shift.end, role: shift.role, status: "open",
                             tenantId: Config.tenantId)
            try await supabase.from("kn_open_shifts").insert(row).execute()
            try await supabase.from("kn_shifts")
                .update(["status": "offered"])
                .eq("id", value: shift.id.uuidString)
                .execute()
            if let fresh = try? await fetchOpenShifts() { openShifts = fresh }
        } catch { errorMessage = error.localizedDescription }
    }

    func submitTimeOff(kind: TimeOff.Kind, startDate: Date, endDate: Date, note: String?) async throws {
        struct Insert: Encodable {
            let employeeId, kind, status, startDate, endDate, tenantId: String
            let note: String?
            enum CodingKeys: String, CodingKey {
                case employeeId = "employee_id"
                case kind, status, note
                case startDate = "start_date"
                case endDate   = "end_date"
                case tenantId  = "tenant_id"
            }
        }
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let row = Insert(employeeId: currentUser.id.uuidString, kind: kind.rawValue,
                         status: "pending", startDate: df.string(from: startDate),
                         endDate: df.string(from: endDate),
                         note: note?.isEmpty == true ? nil : note,
                         tenantId: Config.tenantId)
        try await supabase.from("kn_time_off").insert(row).execute()
        if let fresh = try? await fetchTimeOff() { timeOff = fresh }
        let displayFmt = DateFormatter(); displayFmt.dateFormat = "MMM d"
        let startStr = displayFmt.string(from: startDate)
        let endStr   = displayFmt.string(from: endDate)
        let range    = Calendar.current.isDate(startDate, inSameDayAs: endDate) ? startStr : "\(startStr) – \(endStr)"
        await notifyManagers(icon: "calendar", title: "Time off request",
                             body: "\(currentUser.name) requested \(kind.rawValue) · \(range)",
                             category: "timeOff")
    }

    func pickUpShift(id: UUID) async {
        let openShift = openShifts.first(where: { $0.id == id })
        if let i = openShifts.firstIndex(where: { $0.id == id }) { openShifts[i].status = .pending }
        do {
            try await supabase.from("kn_open_shifts")
                .update(["status": "pending"]).eq("id", value: id.uuidString).execute()
            if let s = openShift {
                await notifyManagers(icon: "calendar", title: "Shift pickup",
                                     body: "\(currentUser.name) wants to pick up \(s.day) \(s.date)",
                                     category: "shift")
            }
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
        let swap = swaps.first(where: { $0.id == id })
        if let i = swaps.firstIndex(where: { $0.id == id }) { swaps[i].status = .approved }
        do {
            try await supabase.from("kn_swaps")
                .update(["status": "approved"]).eq("id", value: id.uuidString).execute()
            if let shiftId = swap?.fromShiftId, let newOwnerId = swap?.withEmployeeId {
                try await supabase.from("kn_shifts")
                    .update(["employee_id": newOwnerId.uuidString])
                    .eq("id", value: shiftId.uuidString)
                    .execute()
            }
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
        guard let request = timeOff.first(where: { $0.id == id }) else { return }
        if let i = timeOff.firstIndex(where: { $0.id == id }) { timeOff[i].status = .approved }
        do {
            try await supabase.from("kn_time_off")
                .update(["status": "approved"]).eq("id", value: id.uuidString).execute()
            // Deduct from employee's PTO balance when approving a PTO request
            if request.kind == .pto, let emp = staff.first(where: { $0.name == request.staffName }) {
                let newBalance = max(0, emp.ptoDaysRemaining - Double(request.days))
                try await supabase.from("employees")
                    .update(["pto_days_remaining": newBalance])
                    .eq("id", value: emp.id.uuidString).execute()
                if let i = staff.firstIndex(where: { $0.id == emp.id }) {
                    staff[i].ptoDaysRemaining = newBalance
                }
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func denyTimeOff(id: UUID) async {
        if let i = timeOff.firstIndex(where: { $0.id == id }) { timeOff[i].status = .denied }
        do {
            try await supabase.from("kn_time_off")
                .update(["status": "denied"]).eq("id", value: id.uuidString).execute()
        } catch { errorMessage = error.localizedDescription }
    }

    func hasShiftConflict(for request: TimeOff) async -> Bool {
        guard let employeeId = request.employeeId,
              !request.startDate.isEmpty, !request.endDate.isEmpty else { return false }
        struct Row: Decodable { let id: UUID }
        let rows: [Row] = (try? await supabase.from("kn_shifts")
            .select("id")
            .eq("employee_id", value: employeeId.uuidString)
            .gte("shift_date", value: request.startDate)
            .lte("shift_date", value: request.endDate)
            .execute().value) ?? []
        return !rows.isEmpty
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

    func reloadSwaps() async {
        if let fresh = try? await fetchSwaps() { swaps = fresh }
    }

    func reloadTimeOff() async {
        if let fresh = try? await fetchTimeOff() { timeOff = fresh }
    }

    func reloadShifts() async {
        if let fresh = try? await fetchShifts() { shift = fresh }
    }

    func fetchLaborBudget() async {
        struct Row: Decodable { let value: String }
        if let row: Row = try? await supabase.from("kn_settings")
            .select("value")
            .eq("key", value: "weekly_labor_budget")
            .eq("tenant_id", value: Config.tenantId)
            .single().execute().value {
            weeklyLaborBudget = Double(row.value) ?? 0
        }
    }

    func saveLaborBudget(_ budget: Double) async {
        weeklyLaborBudget = budget
        try? await supabase.from("kn_settings")
            .upsert(["key": "weekly_labor_budget", "value": String(budget), "tenant_id": Config.tenantId], onConflict: "key,tenant_id")
            .execute()
    }

    func handleNotificationTap(category: String) {
        if isManager {
            selectedTab = category == "message" ? 3 : 4
        } else {
            switch category {
            case "shift", "schedule": selectedTab = 0
            case "message":           selectedTab = 2
            default:                  selectedTab = 3
            }
        }
    }

    func cancelTimeOff(id: UUID) async {
        timeOff.removeAll { $0.id == id }
        do {
            try await supabase.from("kn_time_off").delete().eq("id", value: id.uuidString).execute()
        } catch { errorMessage = error.localizedDescription }
    }

    func cancelSwap(id: UUID) async {
        swaps.removeAll { $0.id == id }
        do {
            try await supabase.from("kn_swaps").delete().eq("id", value: id.uuidString).execute()
        } catch { errorMessage = error.localizedDescription }
    }

    func deactivateEmployee(id: UUID) async {
        staff.removeAll { $0.id == id }
        do {
            try await supabase.from("employees").update(["active": false]).eq("id", value: id.uuidString).execute()
        } catch { errorMessage = error.localizedDescription }
    }

    func updateEmployeeRate(id: UUID, rate: Double) async {
        if let i = staff.firstIndex(where: { $0.id == id }) { staff[i].hourlyRate = rate }
        do {
            try await supabase.from("employees").update(["hourly_rate": rate]).eq("id", value: id.uuidString).execute()
        } catch { errorMessage = error.localizedDescription }
    }

    private func notifyManagers(icon: String, title: String, body: String, category: String) async {
        let managers = staff.filter { $0.role == .manager }
        guard !managers.isEmpty else { return }
        struct NotifInsert: Encodable {
            let employeeId, icon, title, body, category, tenantId: String
            enum CodingKeys: String, CodingKey {
                case employeeId = "employee_id"; case icon, title, body, category
                case tenantId = "tenant_id"
            }
        }
        let rows = managers.map {
            NotifInsert(employeeId: $0.id.uuidString, icon: icon, title: title, body: body,
                        category: category, tenantId: Config.tenantId)
        }
        try? await supabase.from("kn_notifications").insert(rows).execute()
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

    func refreshClockStatuses() async { await computeClockStatuses() }

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

    func submitSwap(withEmployee: StaffMember, shift: Shift?) async {
        struct Insert: Encodable {
            let fromEmployeeId, withEmployeeId, status, tenantId: String
            let fromShiftId: String?
            enum CodingKeys: String, CodingKey {
                case fromEmployeeId = "from_employee_id"
                case withEmployeeId = "with_employee_id"
                case fromShiftId    = "from_shift_id"
                case tenantId       = "tenant_id"
                case status
            }
        }
        do {
            try await supabase.from("kn_swaps")
                .insert(Insert(fromEmployeeId: currentUser.id.uuidString,
                               withEmployeeId: withEmployee.id.uuidString,
                               status: "pending",
                               tenantId: Config.tenantId,
                               fromShiftId: shift?.id.uuidString))
                .execute()
            if let fresh = try? await fetchSwaps() { swaps = fresh }
            await notifyManagers(icon: "arrow.left.arrow.right", title: "Swap request",
                                 body: "\(currentUser.name) wants to swap with \(withEmployee.name)",
                                 category: "swap")
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
            let employeeId, day, shiftDate, startTime, endTime, role, status, tenantId: String
            let note: String?
            enum CodingKeys: String, CodingKey {
                case employeeId = "employee_id"; case day, role, status, note
                case shiftDate = "shift_date"; case startTime = "start_time"; case endTime = "end_time"
                case tenantId = "tenant_id"
            }
        }
        let row = Upsert(employeeId: employeeId.uuidString, day: days[dayIndex],
                         shiftDate: df.string(from: shiftDate),
                         startTime: tf.string(from: start), endTime: tf.string(from: end),
                         role: role.isEmpty ? "Staff" : role, status: "scheduled",
                         note: note.isEmpty ? nil : note, tenantId: Config.tenantId)
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
            let employeeId: String; let eventType: String; let createdAt: Date
            enum CodingKeys: String, CodingKey {
                case employeeId = "employee_id"; case eventType = "event_type"; case createdAt = "created_at"
            }
        }
        let shifts = (try? await supabase.from("kn_shifts").select()
            .eq("shift_date", value: today).execute().value as [DBShift]) ?? []
        let events = (try? await supabase.from("clock_events")
            .select("employee_id, event_type, created_at")
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

        var clockInByEmp: [String: Date] = [:]
        var breakStartByEmp: [String: Date] = [:]
        var breakDurByEmp: [String: TimeInterval] = [:]
        var actualCost = 0.0
        for e in events {
            switch e.eventType {
            case "clock_in":
                clockInByEmp[e.employeeId] = e.createdAt; breakDurByEmp[e.employeeId] = 0
            case "break_start":
                breakStartByEmp[e.employeeId] = e.createdAt
            case "break_end":
                if let bs = breakStartByEmp[e.employeeId] {
                    breakDurByEmp[e.employeeId, default: 0] += e.createdAt.timeIntervalSince(bs)
                    breakStartByEmp.removeValue(forKey: e.employeeId)
                }
            case "clock_out":
                if let ci = clockInByEmp[e.employeeId] {
                    let worked = max(0, e.createdAt.timeIntervalSince(ci) - (breakDurByEmp[e.employeeId] ?? 0))
                    let rate = staff.first(where: { $0.id.uuidString == e.employeeId })?.hourlyRate ?? 0
                    actualCost += (worked / 3600) * rate
                }
                clockInByEmp.removeValue(forKey: e.employeeId)
                breakDurByEmp.removeValue(forKey: e.employeeId)
            default: break
            }
        }

        labor = LaborSummary(actualToday: Int(actualCost),
                             scheduledToday: Int(scheduled),
                             forecastToday: Int(scheduled),
                             pctOfSales: 0,
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
        struct ClockEvent: Decodable {
            let eventType: String; let createdAt: Date
            enum CodingKeys: String, CodingKey {
                case eventType = "event_type"; case createdAt = "created_at"
            }
        }
        let (weekStart, weekEnd) = currentISOWeekBounds()
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let events = (try? await supabase.from("clock_events")
            .select("event_type, created_at")
            .eq("employee_id", value: currentUser.id.uuidString)
            .gte("created_at", value: df.string(from: weekStart) + "T00:00:00")
            .lte("created_at", value: df.string(from: weekEnd) + "T23:59:59")
            .order("created_at", ascending: true)
            .execute().value as [ClockEvent]) ?? []

        let dayFmt = DateFormatter(); dayFmt.dateFormat = "EEE"
        let displayFmt = DateFormatter(); displayFmt.dateFormat = "MMM d"
        var result: [EarningsShift] = []
        var clockInTime: Date? = nil
        var breakStart: Date? = nil
        var breakDuration: TimeInterval = 0

        for event in events {
            switch event.eventType {
            case "clock_in":
                clockInTime = event.createdAt; breakDuration = 0; breakStart = nil
            case "break_start":
                breakStart = event.createdAt
            case "break_end":
                if let bs = breakStart { breakDuration += event.createdAt.timeIntervalSince(bs); breakStart = nil }
            case "clock_out":
                if let ci = clockInTime {
                    let worked = max(0, event.createdAt.timeIntervalSince(ci) - breakDuration)
                    result.append(EarningsShift(day: dayFmt.string(from: ci),
                                                date: displayFmt.string(from: ci),
                                                hours: worked / 3600,
                                                rate: currentUser.hourlyRate))
                }
                clockInTime = nil; breakDuration = 0
            default: break
            }
        }
        earningsShifts = result
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
        var scheduledCostByDay: [Int: Double] = [:]
        var hoursByEmp: [UUID: Double] = [:]

        for s in shifts {
            let hours = hoursFromShift(start: s.startTime, end: s.endTime)
            let rate = staff.first(where: { $0.id == s.employeeId })?.hourlyRate ?? 0
            if let date = df.date(from: s.shiftDate) {
                let weekday = cal.component(.weekday, from: date)
                let dayIdx = (weekday + 5) % 7
                scheduledCostByDay[dayIdx, default: 0] += hours * rate
            }
            hoursByEmp[s.employeeId, default: 0] += hours
        }

        for i in staff.indices {
            staff[i].hoursThisWeek = hoursByEmp[staff[i].id] ?? 0
        }
        for (empId, hours) in hoursByEmp {
            try? await supabase.from("employees")
                .update(["hours_this_week": hours])
                .eq("id", value: empId.uuidString)
                .execute()
        }

        struct ActualClockRow: Decodable {
            let employeeId: UUID; let eventType: String; let createdAt: Date
            enum CodingKeys: String, CodingKey {
                case employeeId = "employee_id"; case eventType = "event_type"; case createdAt = "created_at"
            }
        }
        let clockRows = (try? await supabase.from("clock_events")
            .select("employee_id, event_type, created_at")
            .gte("created_at", value: df.string(from: weekStart) + "T00:00:00")
            .lte("created_at", value: df.string(from: weekEnd) + "T23:59:59")
            .order("created_at", ascending: true)
            .execute().value as [ActualClockRow]) ?? []

        var clockInByEmp: [UUID: Date] = [:]
        var breakStartByEmp: [UUID: Date] = [:]
        var breakDurByEmp: [UUID: TimeInterval] = [:]
        var actualHrs: [UUID: Double] = [:]
        var actualCostByDay: [Int: Double] = [:]

        for e in clockRows {
            switch e.eventType {
            case "clock_in":
                clockInByEmp[e.employeeId] = e.createdAt; breakDurByEmp[e.employeeId] = 0
            case "break_start":
                breakStartByEmp[e.employeeId] = e.createdAt
            case "break_end":
                if let bs = breakStartByEmp[e.employeeId] {
                    breakDurByEmp[e.employeeId, default: 0] += e.createdAt.timeIntervalSince(bs)
                    breakStartByEmp.removeValue(forKey: e.employeeId)
                }
            case "clock_out":
                if let ci = clockInByEmp[e.employeeId] {
                    let worked = max(0, e.createdAt.timeIntervalSince(ci) - (breakDurByEmp[e.employeeId] ?? 0))
                    let workedHrs = worked / 3600
                    actualHrs[e.employeeId, default: 0] += workedHrs
                    let rate = staff.first(where: { $0.id == e.employeeId })?.hourlyRate ?? 0
                    let weekday = cal.component(.weekday, from: e.createdAt)
                    let dayIdx = (weekday + 5) % 7
                    actualCostByDay[dayIdx, default: 0] += workedHrs * rate
                }
                clockInByEmp.removeValue(forKey: e.employeeId)
                breakDurByEmp.removeValue(forKey: e.employeeId)
            default: break
            }
        }

        actualHoursByEmployee = actualHrs
        laborReport = dayNames.enumerated().map { idx, name in
            let scheduled = scheduledCostByDay[idx] ?? 0
            let actual = actualCostByDay[idx] ?? 0
            return LaborDay(day: name, scheduled: scheduled, actual: actual, budget: scheduled * 1.15)
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
            return ScheduleRow(employeeId: member.id, name: member.name, cells: cells)
        }
    }

    func publishSchedule(weekStart: Date) async {
        let df = DateFormatter(); df.dateFormat = "MMM d"
        let label = df.string(from: weekStart)
        struct NotifInsert: Encodable {
            let employeeId, icon, title, body, category, tenantId: String
            enum CodingKeys: String, CodingKey {
                case employeeId = "employee_id"
                case icon, title, body, category
                case tenantId = "tenant_id"
            }
        }
        let inserts = staff.map {
            NotifInsert(employeeId: $0.id.uuidString, icon: "calendar",
                        title: "Schedule published",
                        body: "Your schedule for the week of \(label) is ready.",
                        category: "schedule", tenantId: Config.tenantId)
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
            let threadId, senderId, text, tenantId: String
            enum CodingKeys: String, CodingKey {
                case threadId = "thread_id"; case senderId = "sender_id"; case text
                case tenantId = "tenant_id"
            }
        }
        try await supabase.from("kn_messages")
            .insert(Insert(threadId: threadId.uuidString,
                           senderId: currentUser.id.uuidString, text: text,
                           tenantId: Config.tenantId))
            .execute()
        if let fresh = try? await fetchThreads() { threads = fresh }
    }

    func createThread(withEmployeeId: UUID, initialMessage: String) async throws -> UUID {
        struct ThreadInsert: Encodable {
            let isBroadcast: Bool; let tenantId: String
            enum CodingKeys: String, CodingKey {
                case isBroadcast = "is_broadcast"; case tenantId = "tenant_id"
            }
        }
        struct ParticipantInsert: Encodable {
            let threadId, employeeId, tenantId: String
            enum CodingKeys: String, CodingKey {
                case threadId = "thread_id"; case employeeId = "employee_id"
                case tenantId = "tenant_id"
            }
        }
        let thread: DBThread = try await supabase.from("kn_message_threads")
            .insert(ThreadInsert(isBroadcast: false, tenantId: Config.tenantId))
            .select().single().execute().value
        try await supabase.from("kn_thread_participants")
            .insert([ParticipantInsert(threadId: thread.id.uuidString, employeeId: currentUser.id.uuidString, tenantId: Config.tenantId),
                     ParticipantInsert(threadId: thread.id.uuidString, employeeId: withEmployeeId.uuidString, tenantId: Config.tenantId)])
            .execute()
        try await sendMessage(threadId: thread.id, text: initialMessage)
        return thread.id
    }

    func createBroadcastThread(message: String) async throws {
        struct ThreadInsert: Encodable {
            let isBroadcast: Bool; let broadcastRecipientCount: Int; let tenantId: String
            enum CodingKeys: String, CodingKey {
                case isBroadcast = "is_broadcast"
                case broadcastRecipientCount = "broadcast_recipient_count"
                case tenantId = "tenant_id"
            }
        }
        struct ParticipantInsert: Encodable {
            let threadId, employeeId, tenantId: String
            enum CodingKeys: String, CodingKey {
                case threadId = "thread_id"; case employeeId = "employee_id"
                case tenantId = "tenant_id"
            }
        }
        let count = staff.count
        let thread: DBThread = try await supabase.from("kn_message_threads")
            .insert(ThreadInsert(isBroadcast: true, broadcastRecipientCount: count, tenantId: Config.tenantId))
            .select().single().execute().value
        let allParticipants = staff.map {
            ParticipantInsert(threadId: thread.id.uuidString, employeeId: $0.id.uuidString, tenantId: Config.tenantId)
        }
        if !allParticipants.isEmpty {
            try await supabase.from("kn_thread_participants").insert(allParticipants).execute()
        }
        try await sendMessage(threadId: thread.id, text: message)
    }
}
