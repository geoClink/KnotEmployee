import SwiftUI

struct ScheduleBuilderView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    @State private var published = false
    private let days = [("Mon","9"),("Tue","10"),("Wed","11"),("Thu","12"),("Fri","13"),("Sat","14"),("Sun","15")]

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
        }
    }

    private var weekStepper: some View {
        HStack {
            IconView(icon: .chevronLeft, size: 18, color: theme.inkMuted)
            Spacer()
            VStack(spacing: 1) {
                Text("Jun 9 – 15").font(theme.bodyMedium(14)).foregroundStyle(theme.ink)
                Text("\(store.weekGrid.count) staff · 2 gaps").font(theme.body(11)).foregroundStyle(theme.inkMuted)
            }
            Spacer()
            IconView(icon: .chevronRight, size: 18, color: theme.inkMuted)
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

            ForEach(store.weekGrid) { row in
                HStack(spacing: 4) {
                    Avatar(name: row.name, size: 28).frame(width: 40)
                    ForEach(Array(row.cells.enumerated()), id: \.offset) { _, cell in
                        cellView(cell)
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
            Text("Tap a cell to edit").font(theme.body(11)).foregroundStyle(theme.inkFaint)
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
            Button { published = true } label: {
                HStack(spacing: 6) {
                    IconView(icon: .check, size: 16, color: theme.paper)
                    Text(published ? "Published" : "Publish").font(theme.bodyMedium(15)).foregroundStyle(theme.paper)
                }
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(published ? theme.green : theme.ink, in: Capsule())
            }
            .buttonStyle(.plain)
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
