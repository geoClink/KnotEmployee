import SwiftUI

struct EarningsView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    private var totalHours: Double { store.earningsShifts.reduce(0) { $0 + $1.hours } }
    private var totalGross: Double { store.earningsShifts.reduce(0) { $0 + $1.gross } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    heroCard
                    if store.earningsShifts.isEmpty {
                        Text("No hours recorded this week.")
                            .font(theme.body(14)).foregroundStyle(theme.inkMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 20)
                    } else {
                        section("This week") {
                            VStack(spacing: 10) {
                                ForEach(store.earningsShifts) { shift in
                                    EarningsRow(shift: shift)
                                }
                            }
                        }
                    }
                    disclaimer
                }
                .padding(20)
            }
            .background(theme.cream.ignoresSafeArea())
            .navigationTitle("Earnings")
            .task { await store.fetchEarnings() }
            .refreshable { await store.fetchEarnings() }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ESTIMATED GROSS").font(theme.mono(11)).foregroundStyle(theme.inkFaint)
            Text("$\(totalGross, specifier: "%.2f")")
                .font(theme.display(44)).foregroundStyle(theme.paper)
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    IconView(icon: .clock, size: 16, color: theme.inkFaint)
                    Text("\(totalHours, specifier: "%.1f") hrs")
                        .font(theme.body(13)).foregroundStyle(theme.inkFaint)
                }
                HStack(spacing: 6) {
                    IconView(icon: .dollar, size: 16, color: theme.inkFaint)
                    Text("$\(store.currentUser.hourlyRate, specifier: "%.2f")/hr")
                        .font(theme.body(13)).foregroundStyle(theme.inkFaint)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(theme.ink, in: RoundedRectangle(cornerRadius: theme.rCardLarge))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Estimated gross \(totalGross, specifier: "%.2f") dollars, \(totalHours, specifier: "%.1f") hours at \(store.currentUser.hourlyRate, specifier: "%.2f") per hour")
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(theme.display(18)).foregroundStyle(theme.ink)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private var disclaimer: some View {
        HStack(spacing: 10) {
            IconView(icon: .clock, size: 16, color: theme.inkMuted)
            Text("Earnings are estimated based on scheduled shifts. Actual pay may differ after tips, deductions, and adjustments.")
                .font(theme.body(12)).foregroundStyle(theme.inkSoft)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.creamDeep, in: RoundedRectangle(cornerRadius: theme.rCard))
    }
}

#Preview {
    EarningsView()
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
