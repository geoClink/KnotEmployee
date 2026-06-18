import SwiftUI

struct LaborReportView: View {
    @Environment(\.knotTheme) private var theme
    @Environment(AppStore.self) private var store

    @AppStorage("weeklyLaborBudget") private var weeklyBudget: Double = 0
    @State private var showBudgetInput = false
    @State private var budgetInput = ""

    private var totalActual: Double { store.laborReport.reduce(0) { $0 + $1.actual } }
    private var totalBudget: Double {
        weeklyBudget > 0 ? weeklyBudget : store.laborReport.reduce(0) { $0 + $1.budget }
    }
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
            Button {
                budgetInput = weeklyBudget > 0 ? String(Int(weeklyBudget)) : ""
                showBudgetInput = true
            } label: {
                VStack(spacing: 2) {
                    Text("$\(Int(totalBudget))").font(theme.display(22)).foregroundStyle(theme.ink)
                    HStack(spacing: 3) {
                        Text("Budget").font(theme.body(11)).foregroundStyle(theme.inkMuted)
                        Image(systemName: "pencil").font(.system(size: 9)).foregroundStyle(theme.inkFaint)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(theme.card, in: RoundedRectangle(cornerRadius: theme.rCard))
                .overlay(RoundedRectangle(cornerRadius: theme.rCard).strokeBorder(theme.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Budget: $\(Int(totalBudget)). Tap to edit.")
            .alert("Set weekly budget", isPresented: $showBudgetInput) {
                TextField("e.g. 3000", text: $budgetInput).keyboardType(.numberPad)
                Button("Save") {
                    weeklyBudget = Double(budgetInput) ?? 0
                }
                Button("Clear") { weeklyBudget = 0 }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter a total labor budget for the week. Leave blank to use the default estimate (115% of scheduled cost).")
            }
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

    private var exportFileURL: URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LaborReport.csv")
        let df = DateFormatter(); df.dateFormat = "MMM d yyyy"
        var lines = ["KnotEmployee Labor Report — Week of \(df.string(from: Date()))"]
        lines.append("Name,Job Title,Hours This Week,Rate ($/hr),Estimated Pay ($)")
        for person in store.staff.sorted(by: { $0.name < $1.name }) {
            let pay = person.hoursThisWeek * person.hourlyRate
            lines.append("\"\(person.name)\",\"\(person.jobTitle)\","
                + "\(String(format: "%.1f", person.hoursThisWeek)),"
                + "\(String(format: "%.2f", person.hourlyRate)),"
                + "\(String(format: "%.2f", pay))")
        }
        try? lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private var exportButton: some View {
        ShareLink(item: exportFileURL) {
            HStack(spacing: 6) {
                IconView(icon: .download, size: 16, color: theme.ink)
                Text("Export CSV").font(theme.bodyMedium(15)).foregroundStyle(theme.ink)
            }
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(theme.card, in: Capsule())
            .overlay(Capsule().strokeBorder(theme.line, lineWidth: 1))
        }
        .accessibilityLabel("Export labor report as CSV")
    }
}

#Preview {
    NavigationStack { LaborReportView() }
        .environment(\.knotTheme, BakeryCoTheme())
        .environment(AppStore.sample)
}
