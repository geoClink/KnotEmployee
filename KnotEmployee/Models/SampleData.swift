import Foundation

extension AppStore {
    static var sample: AppStore {
        let maya = StaffMember(name: "Maya Okafor", jobTitle: "Lead Baker",
                   hoursThisWeek: 31.5, hourlyRate: 24, clockStatus: .clockedIn)
        return AppStore(
            currentUser: maya,
            staff: [maya,
                StaffMember(name: "Devon Hale",  jobTitle: "Barista",       hoursThisWeek: 22, hourlyRate: 18, clockStatus: .out),
                StaffMember(name: "Priya Raman", jobTitle: "Cashier",       hoursThisWeek: 18, hourlyRate: 17, clockStatus: .clockedIn),
                StaffMember(name: "Theo Brandt", jobTitle: "Pastry Chef",   hoursThisWeek: 29, hourlyRate: 26, clockStatus: .onBreak),
                StaffMember(name: "Aisha Bello", jobTitle: "Shift Lead",    hoursThisWeek: 33, hourlyRate: 22, clockStatus: .out),
                StaffMember(name: "Jonah Klein", jobTitle: "Dishwasher",    hoursThisWeek: 24, hourlyRate: 16, clockStatus: .clockedIn),
                StaffMember(name: "Elena Voss",  jobTitle: "Store Manager", role: .manager, hoursThisWeek: 38, hourlyRate: 32, clockStatus: .clockedIn)
            ],
            
            shift: [
                Shift(day: "Mon", date: "Jun 9",  start: "6:00 AM", end: "2:00 PM",  role: "Lead Baker", note: "Sourdough + croissant prep."),
                Shift(day: "Wed", date: "Jun 11", start: "6:00 AM", end: "2:00 PM",  role: "Lead Baker"),
                Shift(day: "Thu", date: "Jun 12", start: "7:00 AM", end: "3:00 PM",  role: "Lead Baker"),
                Shift(day: "Fri", date: "Jun 13", start: "6:00 AM", end: "12:00 PM", role: "Lead Baker", note: "Market day — double batch.", breakLabel: "30 min · unpaid"),
                Shift(day: "Sun", date: "Jun 15", start: "7:00 AM", end: "1:00 PM",  role: "Lead Baker")
            ],
            openShifts: [
                OpenShift(offeredBy: "Aisha Bello", day: "Sat", date: "Jun 14",
                          start: "2:00 PM", end: "9:00 PM", role: "Shift Lead", reason: "Family event"),
                OpenShift(offeredBy: "Sofia Mendez", day: "Wed", date: "Jun 18",
                          start: "8:00 AM", end: "4:00 PM", role: "Cashier", reason: "Exam", status: .pending)
            ],
            swaps: [Swap(direction: .outgoing, status: .pending, withName: "Aisha Bello")],
            timeOff: [TimeOff(kind: .pto, status: .approved, range: "Jun 24 – Jun 26", days: 3, note: "Family trip")]
        )
    }
}
