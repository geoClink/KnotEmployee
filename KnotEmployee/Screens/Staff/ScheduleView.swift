import SwiftUI

struct ScheduleView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    private let template: [(String, String)] = [
        ("Mon","9"),("Tue","10"),("Wed","11"),("Thu","12"),("Fri","13"),("Sat","14"),("Sun","15")
    ]
    private var weekDays: [WeekDay] {
        template.map { label, date in
            WeekDay(label: label, date: date, shift: store.shift.first { $0.day == label })
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    weekStepper
                    ScheduleWeekGrid(days: weekDays)
                    summary
                }
                .padding(20)
            }
            .background(theme.cream.ignoresSafeArea())
            .navigationTitle("Schedule")
        }
    }

    private var weekStepper: some View {
        HStack {
            IconView(icon: .chevronLeft, size: 18, color: theme.inkMuted)
            Spacer()
            Text("Jun 9 – 15").font(theme.bodyMedium(14)).foregroundStyle(theme.ink)
            Spacer()
            IconView(icon: .chevronRight, size: 18, color: theme.inkMuted)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(theme.card, in: Capsule())
        .overlay(Capsule().strokeBorder(theme.line, lineWidth: 1))
    }

    private var summary: some View {
        HStack {
            Text("Scheduled this week").font(theme.body(14)).foregroundStyle(theme.inkSoft)
            Spacer()
            Text("\(store.currentUser.hoursThisWeek, specifier: "%.1f") hrs")
                .font(theme.mono(14)).foregroundStyle(theme.ink)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(theme.creamDeep, in: RoundedRectangle(cornerRadius: theme.rCard))
    }
}

#Preview {
    ScheduleView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
