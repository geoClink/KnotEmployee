import Foundation

extension AppStore {
    static var sample: AppStore {
        let maya = StaffMember(name: "Maya Okafor", jobTitle: "Lead Baker",
                               hoursThisWeek: 31.5, hourlyRate: 24)
        return AppStore(
            currentUser: maya,
            staff: [maya,
                StaffMember(name: "Devon Hale", jobTitle: "Barista", hoursThisWeek: 22, hourlyRate: 18),
                StaffMember(name: "Elena Voss", jobTitle: "Store Manager", role: .manager,
                            hoursThisWeek: 38, hourlyRate: 32)],
            shift: [
                Shift(day: "Thu", date: "Jun 12", start: "7:00 AM", end: "3:00 PM", role: "Lead Baker"),
                Shift(day: "Fri", date: "Jun 13", start: "6:00 AM", end: "12:00 PM", role: "Lead Baker",
                      note: "Market day — double batch.", breakLabel: "30 min · unpaid")],
            openShifts: [
                OpenShift(offeredBy: "Aisha Bello", day: "Sat", date: "Jun 14",
                          start: "2:00 PM", end: "9:00 PM", role: "Shift Lead", reason: "Family event")],
            swaps: [Swap(direction: .outgoing, status: .pending, withName: "Aisha Bello")],
            timeOff: [TimeOff(kind: .pto, status: .approved, range: "Jun 24 – Jun 26", days: 3, note: "Family trip")]
        )
    }
}
