import SwiftUI

struct LaborReportView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    private var totalActual: Double { store.laborReport.reduce(0) { $0 + $1.actual } }
    private var totalBudget: Double { store.laborReport.reduce(0) { $0 + $1.budget } }
    private var totalHours: Double { store.staff.reduce(0) { $0 + $1.hoursThisWeek } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryTiles
                if store.laborReport.isEmpty {
                    Text("No shift data for this week.")
                        .font(theme.body(14)).foregroundStyle(theme.inkMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                } else {
                    section("Daily breakdown") {
                        VStack(spacing: 14) {
                            ForEach(store.laborReport) { day in
                                LaborCostBar(data: day)
                            }
                        }
                        .knotCard()
                    }
                }
                exportButton
            }
            .padding(20)
        }
        .background(theme.cream.ignoresSafeArea())
        .navigationTitle("Labor report")
        .task { await store.fetchLaborReport() }
        .refreshable { await store.fetchLaborReport() }
    }

    private var summaryTiles: some View {
        HStack(spacing: 8) {
            statTile("Total labor", "$\(Int(totalActual))")
            statTile("Budget", "$\(Int(totalBudget))")
            statTile("Hours", "\(Int(totalHours))")
        }
    }

    private func statTile(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(theme.display(22)).foregroundStyle(theme.ink)
            Text(label).font(theme.body(11)).foregroundStyle(theme.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
        .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(theme.display(18)).foregroundStyle(theme.ink)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private var exportButton: some View {
        Button {
            // Stub action — CSV export
        } label: {
            HStack(spacing: 6) {
                IconView(icon: .download, size: 16, color: theme.ink)
                Text("Export CSV").font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
            }
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(theme.card, in: Capsule())
            .overlay(Capsule().strokeBorder(theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Export labor report as CSV")
    }
}

#Preview {
    NavigationStack { LaborReportView() }
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
