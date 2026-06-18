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
                Shift(day: "Mon", date: "Jun 9",  start: "06:00", end: "14:00", role: "Lead Baker", note: "Sourdough + croissant prep."),
                Shift(day: "Wed", date: "Jun 11", start: "08:00", end: "16:00", role: "Lead Baker", breakLabel: "30 min · unpaid"),
                Shift(day: "Thu", date: "Jun 12", start: "13:00", end: "21:00", role: "Lead Baker"),
                Shift(day: "Fri", date: "Jun 13", start: "06:00", end: "12:00", role: "Lead Baker", note: "Market day — double batch.", breakLabel: "30 min · unpaid"),
                Shift(day: "Sun", date: "Jun 15", start: "09:00", end: "17:00", role: "Lead Baker")
            ],
            openShifts: [
                OpenShift(offeredBy: "Aisha Bello", day: "Sat", date: "Jun 14",
                          start: "2:00 PM", end: "9:00 PM", role: "Shift Lead", reason: "Family event"),
                OpenShift(offeredBy: "Sofia Mendez", day: "Wed", date: "Jun 18",
                          start: "8:00 AM", end: "4:00 PM", role: "Cashier", reason: "Exam", status: .pending)
            ],
            swaps: [Swap(fromName: "Maya Okafor", direction: .outgoing, status: .pending, withName: "Aisha Bello")],
            timeOff: [
                TimeOff(staffName: "Maya Okafor", kind: .pto, status: .approved, range: "Jun 24 – Jun 26", days: 3, note: "Family trip"),
                TimeOff(staffName: "Devon Hale", kind: .sick, status: .pending, range: "Jun 20 – Jun 21", days: 2, note: "Doctor appointment"),
                TimeOff(staffName: "Priya Raman", kind: .personal, status: .pending, range: "Jun 28", days: 1)
            ],
            threads: [
                MessageThread(participantName: "Elena Voss", lastMessage: "Sounds good, see you then!", timestamp: "2:15 PM", unread: true, messages: [
                    Message(senderName: "Maya Okafor", text: "Hey Elena, could I leave 30 min early on Friday?", timestamp: "1:50 PM", isFromCurrentUser: true),
                    Message(senderName: "Elena Voss", text: "That should be fine — Priya can cover close.", timestamp: "2:10 PM", isFromCurrentUser: false),
                    Message(senderName: "Maya Okafor", text: "Perfect, thank you!", timestamp: "2:12 PM", isFromCurrentUser: true),
                    Message(senderName: "Elena Voss", text: "Sounds good, see you then!", timestamp: "2:15 PM", isFromCurrentUser: false)
                ]),
                MessageThread(participantName: "Aisha Bello", lastMessage: "Can you cover my Saturday close?", timestamp: "Yesterday", unread: false, messages: [
                    Message(senderName: "Aisha Bello", text: "Hey Maya! Can you cover my Saturday close?", timestamp: "Yesterday", isFromCurrentUser: false),
                    Message(senderName: "Maya Okafor", text: "I'll check my schedule and let you know", timestamp: "Yesterday", isFromCurrentUser: true)
                ]),
                MessageThread(participantName: "Devon Hale", lastMessage: "Thanks for the sourdough tips!", timestamp: "Mon", unread: false, messages: [
                    Message(senderName: "Devon Hale", text: "Hey, any tips for the sourdough starter?", timestamp: "Mon", isFromCurrentUser: false),
                    Message(senderName: "Maya Okafor", text: "Feed it every 12 hours and keep it at room temp!", timestamp: "Mon", isFromCurrentUser: true),
                    Message(senderName: "Devon Hale", text: "Thanks for the sourdough tips!", timestamp: "Mon", isFromCurrentUser: false)
                ]),
                MessageThread(participantName: "All Staff", lastMessage: "Schedule for Jun 9–15 is now live.", timestamp: "Sun", unread: false, messages: [
                    Message(senderName: "Elena Voss", text: "Schedule for Jun 9–15 is now live. Check your shifts and flag any conflicts before Thursday.", timestamp: "Sun", isFromCurrentUser: false)
                ], isBroadcast: true, broadcastRecipientCount: 6)
            ],
            notifications: [
                AppNotification(icon: "calendar", title: "Shift tomorrow", body: "6:00 AM – 12:00 PM · Lead Baker", timestamp: "Just now", isRead: false, category: .shift),
                AppNotification(icon: "arrow.left.arrow.right", title: "Swap approved", body: "Your swap with Aisha Bello was approved.", timestamp: "2h ago", isRead: false, category: .swap),
                AppNotification(icon: "checkmark", title: "Time off approved", body: "Jun 24–26 PTO request approved.", timestamp: "Yesterday", isRead: true, category: .timeOff),
                AppNotification(icon: "bubble.left", title: "New message", body: "Elena Voss sent you a message.", timestamp: "Yesterday", isRead: true, category: .message),
                AppNotification(icon: "megaphone", title: "Schedule published", body: "Week of Jun 9–15 has been published.", timestamp: "2 days ago", isRead: true, category: .system)
            ]
        )
    }
}
