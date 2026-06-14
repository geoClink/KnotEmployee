import SwiftUI

struct StaffDetailView: View {
    @Environment(\.knotTheme) private var theme
    let person: StaffMember

    private let history = [
        ("Wed Jun 11", "5:02 AM", "1:08 PM", "8.1"),
        ("Tue Jun 10", "4:58 AM", "1:00 PM", "8.0"),
        ("Mon Jun 9",  "5:05 AM", "1:15 PM", "8.2")
    ]

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
                    statBox("3", "Shifts left")
                    statBox("$\(Int(person.hourlyRate))", "Rate")
                }

                Button { } label: {
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
                    VStack(spacing: 0) {
                        ForEach(Array(history.enumerated()), id: \.offset) { idx, h in
                            HStack {
                                Text(h.0).font(theme.body(14)).foregroundStyle(theme.ink)
                                Spacer()
                                Text("\(h.1) – \(h.2)").font(theme.mono(12)).foregroundStyle(theme.inkMuted)
                                Text("\(h.3)h").font(theme.mono(13)).foregroundStyle(theme.ink)
                                    .frame(width: 44, alignment: .trailing)
                            }
                            .padding(.vertical, 11)
                            if idx < history.count - 1 {
                                Rectangle().fill(theme.lineSoft).frame(height: 1)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                    .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
                }
            }
            .padding(20)
        }
        .background(theme.cream.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
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
}

#Preview {
    NavigationStack {
        StaffDetailView(person: StaffMember(name: "Theo Brandt", jobTitle: "Pastry Chef",
            hoursThisWeek: 29, hourlyRate: 26, clockStatus: .onBreak))
    }
    .environment(\.knotTheme, BakeryCoTheme())
}
