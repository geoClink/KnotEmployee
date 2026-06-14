import SwiftUI

struct TimeOffRequestRow: View {
    @Environment(\.knotTheme) private var theme
    let request: TimeOff

    var body: some View {
        HStack(spacing: 12) {
            dateBlock
            VStack(alignment: .leading, spacing: 2) {
                Text(request.kind.rawValue)
                    .font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                Text(request.range)
                    .font(theme.body(13)).foregroundStyle(theme.inkMuted)
                Text("\(request.days) day\(request.days == 1 ? "" : "s")")
                    .font(theme.body(12)).foregroundStyle(theme.inkFaint)
                    .padding(.top, 1)
            }
            Spacer()
            StatusBadge(status: badge, small: true)
        }
        .knotCard(padding: 13)
        .accessibilityElement(children: .combine)
    }

    private var badge: BadgeStatus {
        switch request.status {
        case .pending:  .pending
        case .approved: .approved
        case .denied:   .denied
        }
    }

    private var dateBlock: some View {
        VStack(spacing: 1) {
            Text(request.kind.rawValue.prefix(3).uppercased())
                .font(theme.bodyMedium(11))
            Text("\(request.days)")
                .font(theme.display(22))
        }
        .frame(width: 50, height: 54)
        .foregroundStyle(theme.inkSoft)
        .background(theme.creamDeep, in: RoundedRectangle(cornerRadius: theme.rCard))
    }
}

#Preview {
    VStack(spacing: 12) {
        TimeOffRequestRow(request: TimeOff(kind: .pto, status: .approved, range: "Jun 24 – Jun 26", days: 3, note: "Family trip"))
        TimeOffRequestRow(request: TimeOff(kind: .sick, status: .pending, range: "Jul 1 – Jul 2", days: 2))
        TimeOffRequestRow(request: TimeOff(kind: .personal, status: .denied, range: "Jul 10", days: 1, note: "Appointment"))
    }
    .padding(20)
    .background(BakeryCoTheme().cream)
    .environment(\.knotTheme, BakeryCoTheme())
}
