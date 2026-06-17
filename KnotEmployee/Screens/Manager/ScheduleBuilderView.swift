import SwiftUI

struct ScheduleBuilderView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    @State private var published = false
    @State private var editRow: Int?
    @State private var editDay: Int?
    @State private var weekOffset = 0

    private var baseMonday: Date {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return cal.date(from: comps) ?? Date()
    }

    private var weekStart: Date {
        Calendar.current.date(byAdding: .day, value: weekOffset * 7, to: baseMonday)!
    }

    private var weekLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
        return "\(fmt.string(from: weekStart)) – \(fmt.string(from: end))"
    }

    private var days: [(String, String)] {
        let cal = Calendar.current
        let dayNames = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        return (0..<7).map { i in
            let date = cal.date(byAdding: .day, value: i, to: weekStart)!
            let num = cal.component(.day, from: date)
            return (dayNames[i], String(num))
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                weekStepper.padding(20)
                ScrollView {
                    grid.padding(.horizontal, 20)
                    legend.padding(.horizontal, 20)
                }
                bottomBar
            }
            .background(theme.cream.ignoresSafeArea())
            .navigationTitle("Schedule")
            .task(id: weekOffset) { await store.fetchWeekGrid(weekStart: weekStart) }
            .onChange(of: weekOffset) { published = false }
            .sheet(isPresented: Binding(
                get: { editRow != nil && editDay != nil },
                set: { if !$0 { editRow = nil; editDay = nil } }
            )) {
                if let r = editRow, let d = editDay {
                    AddEditShiftView(rowIndex: r, dayIndex: d, weekStart: weekStart)
                }
            }
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
            VStack(spacing: 1) {
                Text(weekLabel).font(theme.bodyMedium(14)).foregroundStyle(theme.ink)
                Text("\(store.weekGrid.count) staff · 2 gaps").font(theme.body(11)).foregroundStyle(theme.inkMuted)
            }
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

    private var grid: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Color.clear.frame(width: 40)
                ForEach(days, id: \.0) { d in
                    VStack(spacing: 0) {
                        Text(d.0.uppercased()).font(theme.body(8)).foregroundStyle(theme.inkMuted)
                        Text(d.1).font(theme.bodyMedium(12)).foregroundStyle(theme.ink)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 6)

            ForEach(Array(store.weekGrid.enumerated()), id: \.element.id) { rowIdx, row in
                HStack(spacing: 4) {
                    Avatar(name: row.name, size: 28).frame(width: 40)
                    ForEach(Array(row.cells.enumerated()), id: \.offset) { dayIdx, cell in
                        Button { editRow = rowIdx; editDay = dayIdx } label: {
                            cellView(cell)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(row.name), \(days[dayIdx].0), \(cell ?? "off")")
                    }
                }
                .padding(.vertical, 5)
                .overlay(alignment: .bottom) { Rectangle().fill(theme.lineSoft).frame(height: 1) }
            }
        }
        .padding(8)
        .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
        .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
    }

    private func cellView(_ cell: String?) -> some View {
        Group {
            if let cell {
                Text(cell).font(theme.mono(8.5)).foregroundStyle(theme.roseDeep)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .background(theme.roseSoft, in: RoundedRectangle(cornerRadius: 5))
            } else {
                Text("·").font(theme.body(11)).foregroundStyle(theme.inkFaint)
                    .frame(maxWidth: .infinity, minHeight: 30)
            }
        }
        .padding(.horizontal, 1)
    }

    private var legend: some View {
        HStack(spacing: 14) {
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 3).fill(theme.roseSoft).frame(width: 12, height: 10)
                Text("Shift").font(theme.body(11)).foregroundStyle(theme.inkMuted)
            }
            HStack(spacing: 5) {
                Text("·").foregroundStyle(theme.inkFaint)
                Text("Off").font(theme.body(11)).foregroundStyle(theme.inkMuted)
            }
            Spacer()
            Text("Tap a cell to edit").font(theme.body(11)).foregroundStyle(theme.inkMuted)
        }
        .padding(.vertical, 12)
    }

    private var bottomBar: some View {
        HStack(spacing: 10) {
            Button { } label: {
                Text("Save draft").font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(theme.card, in: Capsule())
                    .overlay(Capsule().strokeBorder(theme.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            Button {
                Task {
                    await store.publishSchedule(weekStart: weekStart)
                    published = true
                }
            } label: {
                HStack(spacing: 6) {
                    IconView(icon: .check, size: 16, color: theme.paper)
                    Text(published ? "Published" : "Publish").font(theme.bodyMedium(15)).foregroundStyle(theme.paper)
                }
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(published ? theme.green : theme.ink, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(published)
        }
        .padding(16)
        .background(theme.cream)
        .overlay(alignment: .top) { Rectangle().fill(theme.line).frame(height: 1) }
    }
}

#Preview {
    ScheduleBuilderView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
