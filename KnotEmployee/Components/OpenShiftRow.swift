import SwiftUI

// Shared card style — used across the app.
struct KnotCard: ViewModifier {
    @Environment(\.knotTheme) private var theme
    var padding: CGFloat = 14
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
            .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
    }
}
extension View {
    func knotCard(padding: CGFloat = 14) -> some View { modifier(KnotCard(padding: padding)) }
}

struct OpenShiftRow: View {
    @Environment(\.knotTheme) private var theme
    let shift: OpenShift
    var onPickUp: () -> Void = {}

    private enum RowState { case available, mine, pending }
    private var state: RowState {
        if shift.status == .pending { return .pending }
        if shift.offeredBy == "You" || shift.status == .offered { return .mine }
        return .available
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                dateBlock
                VStack(alignment: .leading, spacing: 2) {
                    Text(shift.timeRange).font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                    Text(shift.role).font(theme.body(13)).foregroundStyle(theme.inkMuted)
                    HStack(spacing: 5) {
                        IconView(icon: .handoff, size: 13, color: theme.inkFaint)
                        Text(state == .mine ? "You put this up" : "Offered by \(shift.offeredBy)")
                            .font(theme.body(12)).foregroundStyle(theme.inkFaint)
                    }
                    .padding(.top, 3)
                }
                Spacer()
                switch state {
                case .mine:    pill("Awaiting pickup", theme.gold)
                case .pending: StatusBadge(status: .pending, small: true)
                case .available: EmptyView()
                }
            }
            if let reason = shift.reason, !reason.isEmpty {
                Text("“\(reason)”").font(theme.body(12)).foregroundStyle(theme.inkSoft)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.cream, in: RoundedRectangle(cornerRadius: 8))
            }
            if state == .available {
                Button(action: onPickUp) {
                    HStack(spacing: 6) {
                        IconView(icon: .check, size: 16, color: theme.paper)
                        Text("Pick up shift").font(theme.bodyMedium(14)).foregroundStyle(theme.paper)
                    }
                    .frame(maxWidth: .infinity).frame(height: 40)
                    .background(theme.ink, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .knotCard(padding: 12)
        .accessibilityElement(children: .combine)
    }

    private func pill(_ text: String, _ color: Color) -> some View {
        Text(text).font(theme.bodyMedium(11)).foregroundStyle(color)
            .padding(.horizontal, 10).padding(.vertical, 3)
            .background(color.opacity(0.14), in: Capsule())
    }

    private var dateBlock: some View {
        VStack(spacing: 1) {
            Text(shift.day.uppercased()).font(theme.bodyMedium(11))
            Text(shift.date.filter(\.isNumber)).font(theme.display(22))
        }
        .frame(width: 50, height: 54)
        .foregroundStyle(theme.inkSoft)
        .background(theme.creamDeep, in: RoundedRectangle(cornerRadius: theme.rCard))
    }
}

#Preview {
    VStack(spacing: 12) {
        OpenShiftRow(shift: OpenShift(offeredBy: "Aisha Bello", day: "Sat", date: "Jun 14",
                     start: "2:00 PM", end: "9:00 PM", role: "Shift Lead", reason: "Family event"))
        OpenShiftRow(shift: OpenShift(offeredBy: "You", day: "Tue", date: "Jun 17",
                     start: "7:00 AM", end: "3:00 PM", role: "Lead Baker", status: .offered))
        OpenShiftRow(shift: OpenShift(offeredBy: "Devon Hale", day: "Sun", date: "Jun 15",
                     start: "12:00 PM", end: "8:00 PM", role: "Barista", status: .pending))
    }
    .padding(20)
    .background(BakeryCoTheme().cream)
    .environment(\.knotTheme, BakeryCoTheme())
}
