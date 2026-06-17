import SwiftUI

struct EarningsShift: Identifiable {
    let id = UUID()
    var day: String
    var date: String
    var hours: Double
    var rate: Double
    var gross: Double { hours * rate }
}

struct EarningsRow: View {
    @Environment(\.knotTheme) private var theme
    let shift: EarningsShift

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 1) {
                Text(shift.day.uppercased()).font(theme.bodyMedium(11))
                Text(shift.date.filter(\.isNumber)).font(theme.display(22))
            }
            .frame(minHeight: 54).frame(width: 50)
            .foregroundStyle(theme.inkSoft)
            .background(theme.creamDeep, in: RoundedRectangle(cornerRadius: theme.rCard))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(shift.hours, specifier: "%.1f") hrs")
                    .font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                Text("$\(shift.rate, specifier: "%.2f")/hr")
                    .font(theme.body(12)).foregroundStyle(theme.inkMuted)
            }
            Spacer()
            Text("$\(shift.gross, specifier: "%.2f")")
                .font(theme.mono(15)).foregroundStyle(theme.ink)
        }
        .knotCard(padding: 12)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 10) {
        EarningsRow(shift: EarningsShift(day: "Mon", date: "Jun 9", hours: 8, rate: 24))
        EarningsRow(shift: EarningsShift(day: "Wed", date: "Jun 11", hours: 8, rate: 24))
        EarningsRow(shift: EarningsShift(day: "Fri", date: "Jun 13", hours: 6, rate: 24))
    }
    .padding(20)
    .background(BakeryCoTheme().cream)
    .environment(\.knotTheme, BakeryCoTheme())
}
