import SwiftUI

struct StaffRow: View {
    @Environment(\.knotTheme) private var theme
    let person: StaffMember

    var body: some View {
        HStack(spacing: 12) {
            Avatar(name: person.name, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name).font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                Text(person.jobTitle).font(theme.body(12)).foregroundStyle(theme.inkMuted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(status: badge, small: true)
                Text("\(person.hoursThisWeek, specifier: "%.1f")h wk")
                    .font(theme.mono(11)).foregroundStyle(theme.inkMuted)
            }
        }
        .padding(.vertical, 11).padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }

    private var badge: BadgeStatus {
        switch person.clockStatus {
        case .out:       .clockedOut
        case .clockedIn: .clockedIn
        case .onBreak:   .onBreak
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        StaffRow(person: StaffMember(name: "Maya Okafor", jobTitle: "Lead Baker", hoursThisWeek: 31.5, clockStatus: .clockedIn))
        StaffRow(person: StaffMember(name: "Theo Brandt", jobTitle: "Pastry Chef", hoursThisWeek: 29, clockStatus: .onBreak))
        StaffRow(person: StaffMember(name: "Devon Hale", jobTitle: "Barista", hoursThisWeek: 22, clockStatus: .out))
    }
    .padding(20)
    .background(BakeryCoTheme().cream)
    .environment(\.knotTheme, BakeryCoTheme())
}
