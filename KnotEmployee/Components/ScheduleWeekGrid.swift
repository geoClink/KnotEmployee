import SwiftUI

struct WeekDay: Identifiable {
    let id = UUID()
    let label: String   // "Mon"
    let date: String    // "9"
    let shift: Shift?
}

struct ScheduleWeekGrid: View {
    @Environment(\.knotTheme) private var theme
    let days: [WeekDay]
    var onSwap: () -> Void = {}
    var onTimeOff: () -> Void = {}
    var onGiveUp: (Shift) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(days) { day in
                if let shift = day.shift {
                    NavigationLink {
                        ShiftDetailView(shift: shift,
                                        onSwap: onSwap,
                                        onGiveUp: { onGiveUp(shift) },
                                        onTimeOff: onTimeOff)
                    } label: {
                        row(day, shift)
                    }
                    .buttonStyle(.plain)
                } else {
                    row(day, nil)
                }
            }
        }
    }

    private func row(_ day: WeekDay, _ shift: Shift?) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 1) {
                Text(day.label.uppercased()).font(theme.body(10)).foregroundStyle(theme.inkMuted)
                Text(day.date).font(theme.display(19)).foregroundStyle(shift != nil ? theme.ink : theme.inkFaint)
            }
            .frame(width: 46)

            if let shift {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(shift.timeRange).font(theme.bodyMedium(14)).foregroundStyle(theme.ink)
                        Text(shift.role).font(theme.body(12)).foregroundStyle(theme.inkMuted)
                    }
                    Spacer()
                    IconView(icon: .chevronRight, size: 16, color: theme.inkFaint)
                }
                .padding(.horizontal, 12).padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.card, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(theme.line, lineWidth: 1))
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(theme.rose)
                        .frame(width: 3).padding(.vertical, 8)
                }
            } else {
                Text("Off").font(theme.body(12)).foregroundStyle(theme.inkFaint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(theme.line, style: StrokeStyle(lineWidth: 1, dash: [4])))
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            ScheduleWeekGrid(days: [
                WeekDay(label: "Mon", date: "9",  shift: Shift(day: "Mon", date: "Jun 9",  start: "6:00 AM", end: "2:00 PM", role: "Lead Baker")),
                WeekDay(label: "Tue", date: "10", shift: nil),
                WeekDay(label: "Wed", date: "11", shift: Shift(day: "Wed", date: "Jun 11", start: "6:00 AM", end: "2:00 PM", role: "Lead Baker")),
            ]).padding(20)
        }
        .background(BakeryCoTheme().cream)
    }
    .environment(\.knotTheme, BakeryCoTheme())
}
