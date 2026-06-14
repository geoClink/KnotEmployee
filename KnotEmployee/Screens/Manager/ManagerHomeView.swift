import SwiftUI

struct ManagerHomeView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    laborCard
                    section("Alerts") {
                        VStack(spacing: 8) { ForEach(store.alerts) { alertRow($0) } }
                    }
                    section("Quick actions") { quickActions }
                }
                .padding(20)
            }
            .background(theme.cream.ignoresSafeArea())
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MANAGER").font(theme.mono(11)).foregroundStyle(theme.gold)
                .padding(.horizontal, 9).padding(.vertical, 3)
                .background(theme.gold.opacity(0.16), in: Capsule())
            Text("The Bakery Co.").font(theme.display(28)).foregroundStyle(theme.ink)
            Text("Thursday, June 12").font(theme.body(13)).foregroundStyle(theme.inkMuted)
        }
    }

    private var laborCard: some View {
        let l = store.labor
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Labor cost · today").font(theme.body(13)).foregroundStyle(theme.inkFaint)
                Spacer()
                Text("\(l.pctOfSales)% of sales").font(theme.mono(12)).foregroundStyle(theme.paper)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("$\(l.actualToday)").font(theme.display(40)).foregroundStyle(theme.paper)
                Text("/ $\(l.scheduledToday) sched").font(theme.body(13)).foregroundStyle(theme.inkFaint)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(theme.paper.opacity(0.12))
                    Capsule().fill(theme.green)
                        .frame(width: geo.size.width * min(1, Double(l.actualToday) / Double(l.forecastToday)))
                }
            }
            .frame(height: 10)
            HStack {
                Text("● \(l.onClock) on the clock").font(theme.body(12)).foregroundStyle(theme.inkFaint)
                Spacer()
                Text("\(l.scheduledCount) scheduled today").font(theme.body(12)).foregroundStyle(theme.inkFaint)
            }
        }
        .padding(18)
        .background(theme.ink, in: RoundedRectangle(cornerRadius: theme.rCardLarge))
    }

    private func alertRow(_ a: ManagerAlert) -> some View {
        HStack(spacing: 11) {
            IconView(icon: .bell, size: 16, color: sevColor(a.severity))
            Text(a.text).font(theme.body(13)).foregroundStyle(theme.ink)
            Spacer()
            IconView(icon: .chevronRight, size: 16, color: theme.inkFaint)
        }
        .padding(.horizontal, 13).padding(.vertical, 11)
        .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
        .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2).fill(sevColor(a.severity)).frame(width: 3).padding(.vertical, 10)
        }
    }

    private var quickActions: some View {
        let cols = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        return LazyVGrid(columns: cols, spacing: 10) {
            actionCard(.calendar, "Schedule")
            actionCard(.swap, "Approvals")
            actionCard(.users, "Directory")
            actionCard(.chart, "Labor report")
        }
    }

    private func actionCard(_ icon: KnotIcon, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            IconView(icon: icon, size: 20, color: theme.inkSoft)
                .frame(width: 38, height: 38)
                .background(theme.creamDeep, in: RoundedRectangle(cornerRadius: theme.rCard))
            Text(label).font(theme.bodyMedium(14)).foregroundStyle(theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
        .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
    }

    private func sevColor(_ s: ManagerAlert.Severity) -> Color {
        switch s {
        case .high: theme.roseDeep
        case .med:  theme.gold
        case .low:  theme.inkMuted
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(theme.display(18)).foregroundStyle(theme.ink)
            content()
        }
    }
}

#Preview {
    ManagerHomeView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}

