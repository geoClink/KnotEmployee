import SwiftUI

struct StaffDetailView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    let person: StaffMember

    @State private var clockHistory: [(date: String, clockIn: String, clockOut: String, hours: String)] = []
    @State private var shiftsThisWeek = 0
    @State private var showThread = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Avatar(name: person.name, size: 72)
                    Text(person.name).font(theme.display(26)).foregroundStyle(theme.ink)
                    Text(person.jobTitle).font(theme.body(13)).foregroundStyle(theme.inkMuted)
                    StatusBadge(status: badge)
                }

                HStack(spacing: 10) {
                    statBox(String(format: "%.1fh", person.hoursThisWeek), "This week")
                    statBox("\(shiftsThisWeek)", "Shifts")
                    statBox("$\(Int(person.hourlyRate))", "Rate")
                }

                Button { showThread = true } label: {
                    HStack(spacing: 8) {
                        IconView(icon: .message, size: 18, color: theme.ink)
                        Text("Message \(firstName)").font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                    }
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(theme.card, in: Capsule())
                    .overlay(Capsule().strokeBorder(theme.line, lineWidth: 1))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Clock history").font(theme.display(18)).foregroundStyle(theme.ink)
                    if clockHistory.isEmpty {
                        Text("No clock events recorded yet.")
                            .font(theme.body(13)).foregroundStyle(theme.inkMuted)
                            .padding(.vertical, 12)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(clockHistory.enumerated()), id: \.offset) { idx, h in
                                HStack {
                                    Text(h.date).font(theme.body(14)).foregroundStyle(theme.ink)
                                    Spacer()
                                    Text("\(h.clockIn) – \(h.clockOut)")
                                        .font(theme.mono(12)).foregroundStyle(theme.inkMuted)
                                    Text("\(h.hours)h").font(theme.mono(13)).foregroundStyle(theme.ink)
                                        .frame(width: 44, alignment: .trailing)
                                }
                                .padding(.vertical, 11)
                                if idx < clockHistory.count - 1 {
                                    Rectangle().fill(theme.lineSoft).frame(height: 1)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                        .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
                    }
                }
            }
            .padding(20)
        }
        .background(theme.cream.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showThread) {
            MessageThreadView(thread: threadFor(person))
        }
        .task {
            async let history = store.fetchClockHistory(employeeId: person.id)
            async let count = store.fetchShiftsCountThisWeek(employeeId: person.id)
            let (h, c) = await (history, count)
            clockHistory = h
            shiftsThisWeek = c
        }
    }

    private func statBox(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(theme.display(22)).foregroundStyle(theme.ink)
            Text(label).font(theme.body(11)).foregroundStyle(theme.inkMuted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
        .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
    }

    private var badge: BadgeStatus {
        switch person.clockStatus {
        case .out: .clockedOut
        case .clockedIn: .clockedIn
        case .onBreak: .onBreak
        }
    }

    private var firstName: String { person.name.split(separator: " ").first.map(String.init) ?? "" }

    private func threadFor(_ p: StaffMember) -> MessageThread {
        if let existing = store.threads.first(where: { $0.participantName == p.name && !$0.isBroadcast }) {
            return existing
        }
        return MessageThread(targetEmployeeId: p.id, participantName: p.name,
                             lastMessage: "", timestamp: "Now", unread: false, messages: [])
    }
}

#Preview {
    NavigationStack {
        StaffDetailView(person: StaffMember(name: "Theo Brandt", jobTitle: "Pastry Chef",
            hoursThisWeek: 29, hourlyRate: 26, clockStatus: .onBreak))
    }
    .environment(\.knotTheme, BakeryCoTheme())
    .environment(AppStore.sample)
}
