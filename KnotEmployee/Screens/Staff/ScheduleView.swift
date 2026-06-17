import SwiftUI

struct ScheduleView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store
    @State private var showNewSwap = false
    @State private var showNewTimeOff = false

    @State private var weekOffset = 0

    private let baseMonday: Date = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 9))!

    private var weekStart: Date {
        Calendar.current.date(byAdding: .day, value: weekOffset * 7, to: baseMonday)!
    }

    private var weekLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
        return "\(fmt.string(from: weekStart)) – \(fmt.string(from: end))"
    }

    private var weekDays: [WeekDay] {
        let cal = Calendar.current
        let dayNames = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        return (0..<7).map { i in
            let date = cal.date(byAdding: .day, value: i, to: weekStart)!
            let num = cal.component(.day, from: date)
            return WeekDay(label: dayNames[i], date: String(num),
                           shift: weekOffset == 0 ? store.shift.first { $0.day == dayNames[i] } : nil)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    weekStepper
                    ScheduleWeekGrid(days: weekDays,
                                     onSwap: { showNewSwap = true },
                                     onTimeOff: { showNewTimeOff = true },
                                     onGiveUp: { giveUp($0) })
                    summary
                }
                .padding(20)
            }
            .background(theme.cream.ignoresSafeArea())
            .sheet(isPresented: $showNewSwap) { NewSwapView() }
            .sheet(isPresented: $showNewTimeOff) { NewTimeOffView() }
            .navigationTitle("Schedule")
        }
    }

    private var weekStepper: some View {
        HStack {
            Button { weekOffset -= 1 } label: {
                IconView(icon: .chevronLeft, size: 18, color: theme.inkMuted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous week")
            Spacer()
            Text(weekLabel).font(theme.bodyMedium(14)).foregroundStyle(theme.ink)
            Spacer()
            Button { weekOffset += 1 } label: {
                IconView(icon: .chevronRight, size: 18, color: theme.inkMuted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next week")
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(theme.card, in: Capsule())
        .overlay(Capsule().strokeBorder(theme.line, lineWidth: 1))
    }

    private func giveUp(_ shift: Shift) {
        if let i = store.shift.firstIndex(where: { $0.id == shift.id }) {
            store.shift[i].status = .offered
        }
        store.openShifts.append(
            OpenShift(offeredBy: store.currentUser.name, day: shift.day, date: shift.date,
                      start: shift.start, end: shift.end, role: shift.role, status: .open)
        )
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
