import Foundation

// MARK: - DB structs

struct DBEmployee: Decodable {
    let id: UUID
    let name: String
    let role: String
    let permissionLevel: Int
    let hourlyRate: Double?
    let hoursThisWeek: Double?
    let userId: UUID?
    let ptoDaysRemaining: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, role
        case permissionLevel  = "permission_level"
        case hourlyRate       = "hourly_rate"
        case hoursThisWeek    = "hours_this_week"
        case userId           = "user_id"
        case ptoDaysRemaining = "pto_days_remaining"
    }
}

struct DBShift: Decodable {
    let id: UUID
    let employeeId: UUID
    let day: String
    let shiftDate: String
    let startTime: String
    let endTime: String
    let role: String
    let note: String?
    let breakLabel: String?
    let status: String
    let confirmed: Bool?

    enum CodingKeys: String, CodingKey {
        case id, day, role, note, status, confirmed
        case employeeId  = "employee_id"
        case shiftDate   = "shift_date"
        case startTime   = "start_time"
        case endTime     = "end_time"
        case breakLabel  = "break_label"
    }
}

struct DBOpenShift: Decodable {
    let id: UUID
    let offeredById: UUID
    let day: String
    let shiftDate: String
    let startTime: String
    let endTime: String
    let role: String
    let reason: String?
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, day, role, reason, status
        case offeredById = "offered_by_id"
        case shiftDate   = "shift_date"
        case startTime   = "start_time"
        case endTime     = "end_time"
    }
}

struct DBSwap: Decodable {
    let id: UUID
    let fromEmployeeId: UUID
    let withEmployeeId: UUID
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, status
        case fromEmployeeId = "from_employee_id"
        case withEmployeeId = "with_employee_id"
    }
}

struct DBTimeOff: Decodable {
    let id: UUID
    let employeeId: UUID
    let kind: String
    let status: String
    let startDate: String
    let endDate: String
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id, kind, status, note
        case employeeId = "employee_id"
        case startDate  = "start_date"
        case endDate    = "end_date"
    }
}

struct DBNotification: Decodable {
    let id: UUID
    let employeeId: UUID
    let icon: String
    let title: String
    let body: String
    let isRead: Bool
    let category: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, icon, title, body, category
        case employeeId = "employee_id"
        case isRead     = "is_read"
        case createdAt  = "created_at"
    }
}

struct DBThread: Decodable {
    let id: UUID
    let isBroadcast: Bool
    let broadcastRecipientCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case isBroadcast             = "is_broadcast"
        case broadcastRecipientCount = "broadcast_recipient_count"
    }
}

struct DBThreadParticipant: Decodable {
    let threadId: UUID
    let employeeId: UUID

    enum CodingKeys: String, CodingKey {
        case threadId  = "thread_id"
        case employeeId = "employee_id"
    }
}

struct DBMessage: Decodable {
    let id: UUID
    let threadId: UUID
    let senderId: UUID
    let text: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, text
        case threadId  = "thread_id"
        case senderId  = "sender_id"
        case createdAt = "created_at"
    }
}

// MARK: - Converters

private let dbDateParser: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()

private let displayDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MMM d"
    return f
}()

private func formatDBDate(_ iso: String) -> String {
    guard let date = dbDateParser.date(from: iso) else { return iso }
    return displayDateFormatter.string(from: date)
}

extension DBEmployee {
    var toStaffMember: StaffMember {
        StaffMember(
            id: id,
            name: name,
            jobTitle: role,
            role: permissionLevel >= 2 ? .manager : .staff,
            hoursThisWeek: hoursThisWeek ?? 0,
            hourlyRate: hourlyRate ?? 0,
            clockStatus: .out,
            userId: userId,
            ptoDaysRemaining: ptoDaysRemaining ?? 10
        )
    }
}

extension DBShift {
    var toShift: Shift {
        Shift(
            id: id,
            day: day,
            date: formatDBDate(shiftDate),
            shiftDate: shiftDate,
            start: startTime,
            end: endTime,
            role: role,
            note: note,
            breakLabel: breakLabel,
            status: Shift.Status(rawValue: status) ?? .scheduled,
            confirmed: confirmed ?? false
        )
    }
}

extension DBOpenShift {
    func toOpenShift(offeredByName: String) -> OpenShift {
        OpenShift(
            id: id,
            offeredBy: offeredByName,
            day: day,
            date: formatDBDate(shiftDate),
            start: startTime,
            end: endTime,
            role: role,
            reason: reason,
            status: OpenShift.Status(rawValue: status) ?? .open
        )
    }
}

extension DBSwap {
    func toSwap(fromName: String, withName: String, currentEmployeeId: UUID) -> Swap {
        let direction: Swap.Direction = fromEmployeeId == currentEmployeeId ? .outgoing : .incoming
        return Swap(
            id: id,
            fromName: fromName,
            direction: direction,
            status: Swap.Status(rawValue: status) ?? .pending,
            withName: withName
        )
    }
}

extension DBTimeOff {
    func toTimeOff(staffName: String) -> TimeOff {
        let start = dbDateParser.date(from: startDate) ?? Date()
        let end   = dbDateParser.date(from: endDate)   ?? Date()
        let days  = max(1, Calendar.current.dateComponents([.day], from: start, to: end).day! + 1)
        let range = days == 1
            ? displayDateFormatter.string(from: start)
            : "\(displayDateFormatter.string(from: start)) – \(displayDateFormatter.string(from: end))"

        let timeOffKind: TimeOff.Kind = {
            switch kind {
            case "PTO":      return .pto
            case "Sick":     return .sick
            default:         return .personal
            }
        }()
        let timeOffStatus: TimeOff.Status = {
            switch status {
            case "approved": return .approved
            case "denied":   return .denied
            default:         return .pending
            }
        }()
        return TimeOff(id: id, staffName: staffName, employeeId: employeeId,
                       kind: timeOffKind, status: timeOffStatus, range: range,
                       days: days, note: note, startDate: startDate, endDate: endDate)
    }
}

extension DBNotification {
    var toNotification: AppNotification {
        let cat: AppNotification.Category = {
            switch category {
            case "shift":   return .shift
            case "swap":    return .swap
            case "timeOff": return .timeOff
            case "message": return .message
            default:        return .system
            }
        }()
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .abbreviated
        let ts = fmt.localizedString(for: createdAt, relativeTo: Date())
        return AppNotification(id: id, icon: icon, title: title, body: body,
                               timestamp: ts, isRead: isRead, category: cat)
    }
}
